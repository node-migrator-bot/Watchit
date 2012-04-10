fs      = require 'fs'
path    = require 'path'
watchit = require '../src/watchit'

delay   = (func) -> setTimeout func, 50
fixture = (pathes...) -> path.join __dirname, 'fixtures', pathes...

exports['watchit can monitor several children'] = (test) ->
  try
    fs.mkdirSync fixture 'musketeers'
  try
    fs.writeFileSync (fixture 'musketeers', 'Athos.test'), ''
  try
    fs.unlinkSync fixture 'musketeers', 'Porthos.test'
  try
    fs.unlinkSync fixture 'musketeers', 'Aramis.test'

  changeCount = 0
  createCount = 0
  unlinkCount = 0

  emitter = watchit (fixture 'musketeers'), include: true
  emitter.on 'change', -> changeCount++
  emitter.on 'create', -> createCount++
  emitter.on 'unlink', -> unlinkCount++

  delay ->
    fs.writeFileSync (fixture 'musketeers', 'Porthos.test'), ''
    delay ->
      test.equal 1, createCount, '1 file created'
      fs.writeFileSync (fixture 'musketeers', 'Athos.test'), 'All for one!'
      delay ->
        test.equal 1, changeCount, '1 file changed'
        fs.writeFileSync (fixture 'musketeers', 'Aramis.test'), ''
        delay ->
          test.equal 2, createCount, '2 files created'
          fs.unlinkSync fixture 'musketeers', 'Athos.test'
          fs.unlinkSync fixture 'musketeers', 'Porthos.test'
          fs.unlinkSync fixture 'musketeers', 'Aramis.test'
          delay ->
            test.equal 1, changeCount, '1 file changed (still)'
            test.equal 2, createCount, '2 files created (still)'
            test.equal 3, unlinkCount, '3 files unlinked'
            test.done()
