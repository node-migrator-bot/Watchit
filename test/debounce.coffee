fs      = require 'fs'
path    = require 'path'
watchit = require '../src/watchit'

delay   = (func) -> setTimeout func, 50
fixture = (pathes...) -> path.join __dirname, 'fixtures', pathes...

exports['watchit can group changes together by debouncing'] = (test) ->
  changeCount = 0

  file = fixture 'deb.test'
  fs.writeFileSync file, ''
  emitter = watchit file, debounce: true
  emitter.on 'change', -> changeCount++

  delay ->
    for i in [0..500] by 10
      setTimeout (-> fs.writeFileSync file, "#{i}"), i

    setTimeout ->
      test.equal 1, changeCount
      test.done()
    , 1050