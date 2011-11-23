watchit = require '../src/watchit'
fs = require 'fs'

delay = (func) -> setTimeout func, 50

exports['watchit can group changes together by debouncing'] = (test) ->
  changeCount = 0

  emitter = watchit 'fixtures/deb.test', debounce: true
  emitter.on 'change', -> changeCount++

  delay ->
    for i in [0..500] by 10
      setTimeout (-> fs.writeFileSync 'fixtures/deb.test', "#{i}"), i

    setTimeout (->
      test.equal 1, changeCount
      test.done()
    ), 1050