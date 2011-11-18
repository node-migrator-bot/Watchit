{EventEmitter} = require 'events'
fs             = require 'fs'
path           = require 'path'

# Options:
# * `retain` means that if something is later created at the same location
# as the target, the new entity will be watched.
# * `include` means that if the target is a directory, files contained in that
# directory will be treated like targets. (Otherwise, directory events will
# be forwarded directly from `fs.watch`.)
# * `follow` means that if a target is moved, it will still be watched. If
# both `retain` and `follow` are enabled, then both paths will be watched.
# * `recurse` means that if the target is a directory, all of its
# subdirectories will also be counted as targets.
# * `persistent` is identical to `fs.watch`'s `persistent` option. If
# disabled, the process may exit while files are being watched.
defaults =
  retain: false
  include: false
  follow: false
  recurse: false
  persistent: true

# ## Main function
watchit = (target, options, callback) ->
  # The options argument and the callback are both optional
  if typeof options is 'function'
    callback = options
    options = {}

  options = extend {}, defaults, options ? {}

  # `emitter` will be returned from the function; it emits "change", "create",
  # and "unlink" events. It also emits "success" and "failure" events the
  # first time a target is found or not found, respectively.
  emitter = options.emitter = options.emitter ? new WatchitEmitter(callback)

  # `emitter` also keeps track of targets to prevent us from watching the same
  # target more than once with `include`/`recurse`.
  emitter.targets ?= {}
  return null if emitter.targets[target]
  emitter.targets[target] = true

  # The emitter can also be used to stop the watching process. Because the
  # same emitter is used for directory children (if `include` or `recurse` is
  # enabled), a single "close" event can shut down several `fswatcher`s.
  fswatcher = null
  emitter.close = -> emitter.emit 'close', target
  emitter.on 'close', -> fswatcher?.close()

  # Start watching
  do watchTarget = ->
    fs.stat target, (err, stats) ->
      fail = (err) ->
        if options.retain
          notifyWhenExists target, ->
            emitter.emit 'create', target
            watchTarget()
        else
          emitter.emit 'failure', target, err

      return fail err if err

      try
        if stats.isDirectory()
          fswatcher = watchTargetDir()
          scanTargetDir true if options.include or options.recurse
        else
          fswatcher = watchTargetFile()
      catch e
        return fail e

      emitter.emit 'success', target
      fswatcher.on 'error', (err) -> throw err

  # If the target is lost and `retain` is enabled, we `watchTarget` again
  retainTarget = watchTarget

  # If the target is lost and `follow` is disabled, we close the `FSWatcher`
  unwatchTarget = ->
    fswatcher.close()
    delete emitter.targets[target] unless options.retain

  watchTargetFile = ->
    fs.watch target, {persistent: options.persistent}, (event) ->
      if event is 'rename'
        # Has the target been unlinked, or merely replaced?
        console.log "fs.stat", target
        fs.stat target, (err) ->
          if err
            unwatchTarget() unless options.follow
            retainTarget() if options.retain
            console.log "Retaining #{target}: #{options.retain}"
            # TODO: Distinguish renames from unlinks, somehow
            emitter.emit 'unlink', target
          else
            emitter.emit 'change', target
      else if event is 'change'
        emitter.emit 'change', target

  watchTargetDir = ->
    fs.watch target, {persistent: options.persistent}, (event, filename) ->
      if event is 'rename'
        # Is this happening to the target, or one of its children?
        fs.stat target, (err) ->
          if err
            unwatchTarget() unless options.follow
            retainTarget() if options.retain
            emitter.emit 'unlink', target
          else
            emitter.emit 'rename', target unless options.include
            scanTargetDir() if options.include or options.recurse
      else
        throw new Error "Unexpected directory event: #{event}"

  scanTargetDir = (initial) ->
    fs.readdir target, (err, items) ->
      return if err
      for item in items
        do (item) ->
          fs.stat itemPath = path.join(target, item), (err, stats) ->
            return if err
            isDir = stats.isDirectory()
            if (isDir and options.recurse) or (!isDir and options.include)
              # `watchit` returns null if target is already watched
              if watchit itemPath, extend({emitter}, options)
                if initial
                  emitter.emit 'success', itemPath
                else
                  emitter.emit 'create', itemPath

  emitter

# ## Helpers

class WatchitEmitter extends EventEmitter
  constructor: (@callback) ->
  emit: (event, filename, etc...) ->
    super event, filename, etc...
    super 'all', event, filename, etc...
    @callback? event, filename, etc...

extend = (obj, sources...) ->
  for source in sources
    for prop of source
      obj[prop] = source[prop] if prop of source
  obj

# To be notified when `target` does not exist, we must watch its parent.
notifyWhenExists = (target, callback) ->
  throw new Error 'notifyWhenExists requires a callback' unless callback
  parentDir = path.join target, '..'

  # And if `parentDir` does not exist, we must watch its parent. And so on...
  levelUp = ->
    notifyWhenExists parentDir, ->
      notifyWhenExists target, callback

  path.exists target, (exists) ->
    return callback() if exists

    try
      fswatcher = fs.watch parentDir, {persistent: options.persistent}, ->
        fs.readdir parentDir, (err, items) ->
          if err
            # parentDir no longer exists
            fswatcher.close()
            levelUp()
            return
          for item in items
            if path.join(parentDir, item) is target
              # Our target now exists
              fswatcher.close()
              return callback()
        return
    catch e
      levelUp()

# While Watchit's main export is its titular function, functions which can be
# tested independently are attached.
module.exports = watchit
module.exports.notifyWhenExists = notifyWhenExists