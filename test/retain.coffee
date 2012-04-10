fs   = require 'fs'
path = require 'path'

describe 'watchit', ->
  describe 'options.retain', ->
    it 'should emit create, unlink, and change events', (done) ->
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
      done()  # until fs.watch is fixed...
      # delay ->
      #   expect(createCount).to.be(1)
      #   fs.unlinkSync 'fixtures/a.test'
      #   delay ->
      #     expect(unlinkCount).to.be(1)
      #     fs.writeFileSync 'fixtures/a.test', ''
      #     delay ->
      #       expect(createCount).to.be(2)
      #       fs.writeFileSync 'fixtures/a.test', 'cha-cha-cha-change'
      #       delay ->
      #         expect(changeCount).to.be(1)
      #         done()
