fs      = require 'fs'
path    = require 'path'
watchit = require '../src/watchit'

delay   = (func) -> setTimeout func, 50
fixture = (pathes...) -> path.join __dirname, 'fixtures', pathes...

exports['should not watch ignored files'] = (test) ->
  changed  = no
  options  = {ignored: /^\./, include: yes, recurse: yes}
  watcher  = watchit 'fixtures', options, (event, file) ->
    return if event not in ['create', 'unlink', 'change']
    changed = yes
  fs.writeFileSync fixture '.meh'
  delay ->
    test.equal no, changed
    fs.unlinkSync fixture '.meh'
    delay ->
      test.equal no, changed
      watcher.close()
      test.done()
