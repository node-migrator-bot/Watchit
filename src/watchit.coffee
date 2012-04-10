{EventEmitter} = require 'events'
fs             = require 'fs'
path           = require 'path'

# Options:
# * `retain` means that if something is later created at the same location
# as the target, the new entity will be watched.
# * `debounce` means that changes that occur within 1 second of each other
# will be treated as a single change. This also allows "echo" events that
# occur under OS X to be ignored.
# * `include` means that if the target is a directory, files contained in that
# directory will be treated like targets. (Otherwise, directory events will
# be forwarded directly from `fs.watch`.)
# * `recurse` means that if the target is a directory, all of its
# subdirectories will also be counted as targets.
# * `persistent` is identical to `fs.watch`'s `persistent` option. If
# disabled, the process may exit while files are being watched.
# * `ignore` could contain RegExp pattern or function against which
# added files will be tested.
defaults =
  retain: false
  debounce: false
  include: false
  recurse: false
  persistent: true
  ignored: null

# ## Main function
watchit = (target, options, callback) ->
  # The options argument and the callback are both optional
  if typeof options is 'function'
    callback = options
    options = {}

  options = extend {}, defaults, options ? {}

  # Generic function that will check if some file is ignored.
  ignored = (file) ->
    if options.ignored
      if typeof options.ignored.test is 'function'
        options.ignored.test(file)
      else
        options.ignored(file)
    else
      no

  # `emitter` will be returned from the function; it emits "change", "create",
  # and "unlink" events. It also emits "success" and "failure" events the
  # first time a target is found or not found, respectively.
  emitter = options.emitter = options.emitter ? new WatchitEmitter(callback)

  # `emitter` also keeps track of the mtime on each target. If a target is
  # already being watched on the same emitter, we return `null` rather than
  # watch the same target multiple times.
  emitter.targets ?= {}
  return null if emitter.targets[target]

  # The emitter can also be used to stop the watching process. Because the
  # same emitter is used for directory children (if `include` or `recurse` is
  # enabled), a single "close" event can shut down several `fswatcher`s.
  fswatcher = null
  emitter.close = -> emitter.emit 'close', target
  emitter.on 'close', -> fswatcher?.close()

  # Start watching
  do watchTarget = ->
    emitter.targets[target] = {}
    fs.stat target, (err, stats) ->
      fail = (err) ->
        if options.retain
          notifyWhenExists target, ->
            emitter.emit 'create', target
            watchTarget()
        else
          emitter.emit 'failure', target, err

      return fail err if err

      emitter.targets[target].stats = stats
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

  # If the target is lost, we close the `FSWatcher`
  unwatchTarget = ->
    fswatcher.close()
    delete emitter.targets[target]

  watchTargetFile = ->
    fs.watch target, {persistent: options.persistent}, (event) ->
      if event is 'rename'
        # Has the target been unlinked, or merely replaced?
        fs.stat target, (err) ->
          if err
            unwatchTarget()
            retainTarget() if options.retain
            # TODO: Distinguish renames from unlinks, somehow
            emitter.emit 'unlink', target
          else
            emitter.emit 'change', target
      else if event is 'change'
        if options.debounce
          conditionalTimeout target, 1000, ->
            fs.stat target, (err, stats) ->
              return if err or target not of emitter.targets
              prevStats = emitter.targets[target].stats
              return if stats.mtime.getTime() is prevStats.mtime.getTime()
              emitter.targets[target].stats = stats
              emitter.emit 'change', target
        else
          emitter.emit 'change', target

  watchTargetDir = ->
    fs.watch target, {persistent: options.persistent}, (event, filename) ->
      if event is 'rename'
        # Is this happening to the target, or one of its children?
        fs.stat target, (err) ->
          if err
            unwatchTarget()
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
          return if ignored item
          itemPath = path.join(target, item)
          fs.stat itemPath, (err, stats) ->
            return if err
            isDir = stats.isDirectory()
            if (isDir and options.recurse) or (!isDir and options.include)
              # `watchit` returns null if target is already watched
              if watchit itemPath, extend({emitter}, options)
                emitter.emit 'create', itemPath unless initial

  emitter

# ## Helpers

class WatchitEmitter extends EventEmitter
  constructor: (@callback) ->
  emit: (event, filename, etc...) ->
    return if event is 'newListener'
    super event, filename, etc...
    super 'all', event, filename, etc...
    @callback? event, filename, etc...

extend = (obj, sources...) ->
  for source in sources
    for prop of source
      obj[prop] = source[prop] if prop of source
  obj

# Set a timeout, unless a timeout with the same key already exists.
pendingTimeouts = {}
conditionalTimeout = (key, time, callback) ->
  return if key of pendingTimeouts
  pendingTimeouts[key] = 1
  setTimeout (->
    delete pendingTimeouts[key]
    callback()
  ), time

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
module.exports.conditionalTimeout = conditionalTimeout
module.exports.notifyWhenExists = notifyWhenExists