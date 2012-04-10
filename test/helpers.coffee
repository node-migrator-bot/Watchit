fs   = require 'fs'
path = require 'path'

describe 'helpers', ->
  describe 'conditionalTimeout', ->
    it 'can be used to debounce a function', (done) ->
      callCount = 0
      conditionalTimeout 'foo', 10, -> callCount++
      conditionalTimeout 'foo', 10, -> callCount++
      conditionalTimeout 'foo', 10, -> callCount++
      delay 20, ->
        expect(callCount).to.be(1)
        done()

  describe 'notifyWhenExists', ->
    it 'should call back if the target already exists', (done) ->
      file = fixture 'a.test'
      fs.writeFileSync file, ''
      notifyWhenExists file, ->
        fs.unlinkSync file
        done()

    it 'should not call back before target exists', (done) ->
      exists = no
      file = fixture 'b.test'
      try
        fs.unlinkSync file
      delay 20, ->
        fs.writeFileSync file, ''
        exists = yes
      notifyWhenExists file, ->
        expect(exists).to.be(yes)
        done()

    it 'should work if target has no parent dir', (done) ->
      exists = no
      parent = fixture 'parent'
      child  = fixture 'parent', 'child.test'
      file   = fixture 'parent', 'child.test'
      try
        fs.unlinkSync parent
      try
        fs.rmdirSync parent
      delay 40, ->
        fs.mkdirSync parent
        fs.writeFileSync child, ''
        exists = yes
      notifyWhenExists child, ->
        expect(exists).to.be(yes)
        done()
