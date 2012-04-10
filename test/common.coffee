path = require 'path'

global.expect  = require 'expect.js'
global.delay   = (time, func) ->
  unless func?
    func = time
    time = 50
  setTimeout func, time
global.fixture = (pathes...) -> path.join __dirname, 'fixtures', pathes...
global.watchit = watchit = require '../src/watchit'
global.conditionalTimeout = watchit.conditionalTimeout
global.notifyWhenExists = watchit.notifyWhenExists
