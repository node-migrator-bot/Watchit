watchit = require '../src/watchit'
fs = require 'fs'

delay = (func) -> setTimeout func, 50

exports['watchit emits create, unlink, and change events'] = (test) ->
  try
    fs.unlinkSync 'fixtures/a.test'

  changeCount = 0
  createCount = 0
  unlinkCount = 0

  emitter = watchit 'fixtures/a.test', retain: true
  emitter.on 'change', -> changeCount++
  emitter.on 'create', -> createCount++
  emitter.on 'unlink', -> unlinkCount++

  fs.writeFileSync 'fixtures/a.test', ''
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