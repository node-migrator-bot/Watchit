fs   = require 'fs'
path = require 'path'
{conditionalTimeout, notifyWhenExists} = require '../src/watchit'

delay   = (func) -> setTimeout func, 20
fixture = (pathes...) -> path.join __dirname, 'fixtures', pathes...

exports['conditionalTimeout can be used to debounce a function'] = (test) ->
  callCount = 0
  conditionalTimeout 'foo', 10, -> callCount++
  conditionalTimeout 'foo', 10, -> callCount++
  conditionalTimeout 'foo', 10, -> callCount++
  delay ->
    test.equal callCount, 1
    test.done()

exports['notifyWhenExists calls back if the target already exists'] = (test) ->
  file = fixture 'a.test'
  fs.writeFileSync file, ''
  notifyWhenExists file, ->
    fs.unlinkSync file
    test.done()

exports['notifyWhenExists does not call back before target exists'] = (test) ->
  exists = false
  file = fixture 'b.test'
  try
    fs.unlinkSync file
  delay ->
    fs.writeFileSync file, ''
    exists = true
  notifyWhenExists file, ->
    test.equal true, exists
  test.done()

exports['notifyWhenExists works if target has no parent dir'] = (test) ->
  exists = false
  parent = fixture 'parent'
  child  = fixture 'parent', 'child.test'
  file = fixture 'parent', 'child.test'
  try
    fs.unlinkSync parent
  try
    fs.rmdirSync parent
  delay ->
    fs.mkdirSync parent
    fs.writeFileSync child, ''
    exists = true
  notifyWhenExists child, ->
    test.equal true, exists
    test.done()