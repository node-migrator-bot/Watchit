watchit = require '../src/watchit'
fs = require 'fs'

delay = (func) -> setTimeout func, 50

exports['watchit can monitor several children'] = (test) ->
  try
    fs.mkdirSync 'fixtures/musketeers'
  try
    fs.writeFileSync 'fixtures/musketeers/Athos.test', ''
  try
    fs.unlinkSync 'fixtures/musketeers/Porthos.test'
  try
    fs.unlinkSync 'fixtures/musketeers/Aramis.test'

  changeCount = 0
  createCount = 0
  unlinkCount = 0

  emitter = watchit 'fixtures/musketeers', include: true
  emitter.on 'change', -> changeCount++
  emitter.on 'create', -> createCount++
  emitter.on 'unlink', -> unlinkCount++

  delay ->
    fs.writeFileSync 'fixtures/musketeers/Porthos.test', ''
    delay ->
      test.equal 1, createCount, '1 file created'
      fs.writeFileSync 'fixtures/musketeers/Athos.test', 'All for one!'
      delay ->
        test.equal 1, changeCount, '1 file changed'
        fs.writeFileSync 'fixtures/musketeers/Aramis.test', ''
        delay ->
          test.equal 2, createCount, '2 files created'
          fs.unlinkSync 'fixtures/musketeers/Athos.test'
          fs.unlinkSync 'fixtures/musketeers/Porthos.test'
          fs.unlinkSync 'fixtures/musketeers/Aramis.test'
          delay ->
            test.equal 1, changeCount, '1 file changed (still)'
            test.equal 2, createCount, '2 files created (still)'
            test.equal 3, unlinkCount, '3 files unlinked'
            test.done()
