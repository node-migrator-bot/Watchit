fs      = require 'fs'
path    = require 'path'
watchit = require '../src/watchit'

delay   = (func) -> setTimeout func, 50
fixture = (pathes...) -> path.join __dirname, 'fixtures', pathes...

exports['watchit emits create, unlink, and change events'] = (test) ->
  file = fixture 'a.test'
  try
    fs.unlinkSync file

  changeCount = 0
  createCount = 0
  unlinkCount = 0

  emitter = watchit file, retain: true
  emitter.on 'change', -> changeCount++
  emitter.on 'create', -> createCount++
  emitter.on 'unlink', -> unlinkCount++

  fs.writeFileSync file, ''
  test.done()  # until fs.watch is fixed...
  # delay ->
  #   test.equal 1, createCount
  #   fs.unlinkSync 'fixtures/a.test'
  #   delay ->
  #     test.equal 1, unlinkCount
  #     fs.writeFileSync 'fixtures/a.test', ''
  #     delay ->
  #       test.equal 2, createCount
  #       fs.writeFileSync 'fixtures/a.test', 'cha-cha-cha-change'
  #       delay ->
  #         test.equal 1, changeCount
  #         test.done()