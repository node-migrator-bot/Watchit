{conditionalTimeout, notifyWhenExists} = require '../src/watchit'
fs = require 'fs'

delay = (func) -> setTimeout func, 20

exports['conditionalTimeout can be used to debounce a function'] = (test) ->
  callCount = 0
  conditionalTimeout 'foo', 10, -> callCount++
  conditionalTimeout 'foo', 10, -> callCount++
  conditionalTimeout 'foo', 10, -> callCount++
  delay ->
    test.equal callCount, 1
    test.done()

exports['notifyWhenExists calls back if the target already exists'] = (test) ->
  fs.writeFileSync 'fixtures/a.test', ''
  notifyWhenExists 'fixtures/a.test', ->
      fs.unlinkSync 'fixtures/a.test'
      test.done()

exports['notifyWhenExists does not call back before target exists'] = (test) ->
  exists = false
  try
    fs.unlinkSync 'fixtures/b.test'
  delay ->
    fs.writeFileSync('fixtures/b.test', '')
    exists = true
  notifyWhenExists 'fixtures/b.test', ->
    test.equal true, exists
  test.done()

exports['notifyWhenExists works if target has no parent dir'] = (test) ->
  exists = false
  try
    fs.unlinkSync 'fixtures/parent/child.test'
  try
    fs.rmdirSync 'fixtures/parent'
  delay ->
    fs.mkdirSync 'fixtures/parent'
    fs.writeFileSync 'fixtures/parent/child.test', ''
    exists = true
  notifyWhenExists 'fixtures/parent/child.test', ->
    test.equal true, exists
    test.done()