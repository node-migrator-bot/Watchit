watchit = require '../src/watchit'
fs = require 'fs'

delay = (func) -> setTimeout func, 50

exports['should not watch ignored files'] = (test) ->
  changed  = no
  options  = {ignored: /^\./, include: yes, recurse: yes}
  watcher  = watchit 'fixtures', options, (event, file) ->
    return if event not in ['create', 'unlink', 'change']
    changed = yes
  fs.writeFileSync 'fixtures/.meh'
  delay ->
    test.equal no, changed
    fs.unlinkSync 'fixtures/.meh'
    delay ->
      test.equal no, changed
      watcher.close()
      test.done()
