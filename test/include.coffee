fs   = require 'fs'
path = require 'path'

describe 'watchit', ->
  describe 'options.ignored', ->
    it 'should monitor several children', (done) ->
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

      emitter = watchit (fixture 'musketeers'), include: yes
      emitter.on 'change', -> changeCount++
      emitter.on 'create', -> createCount++
      emitter.on 'unlink', -> unlinkCount++

      delay ->
        fs.writeFileSync (fixture 'musketeers', 'Porthos.test'), ''
        delay ->
          expect(createCount).to.be(1)
          fs.writeFileSync (fixture 'musketeers', 'Athos.test'), 'All for one!'
          delay ->
            expect(changeCount).to.be(1)
            fs.writeFileSync (fixture 'musketeers', 'Aramis.test'), ''
            delay ->
              expect(createCount).to.be(2)
              fs.unlinkSync fixture 'musketeers', 'Athos.test'
              fs.unlinkSync fixture 'musketeers', 'Porthos.test'
              fs.unlinkSync fixture 'musketeers', 'Aramis.test'
              delay ->
                expect(changeCount).to.be(1)
                expect(createCount).to.be(2)
                expect(unlinkCount).to.be(3)
                done()
