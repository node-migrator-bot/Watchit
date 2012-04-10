fs   = require 'fs'
path = require 'path'

describe 'watchit', ->
  describe 'options.debounce', ->
    it 'should group changes together by debouncing', (done) ->
      changeCount = 0

      file = fixture 'deb.test'
      fs.writeFileSync file, ''
      emitter = watchit file, debounce: true
      emitter.on 'change', -> changeCount++

      delay ->
        for i in [0..500] by 10
          setTimeout (-> fs.writeFileSync file, "#{i}"), i

        setTimeout ->
          expect(changeCount).to.be(1)
          done()
        , 1050
