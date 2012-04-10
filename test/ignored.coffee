fs   = require 'fs'
path = require 'path'

describe 'watchit', ->
  describe 'options.ignored', ->
    it 'should not watch ignored files', (done) ->
      changed  = no
      options  = {ignored: /^\./, include: yes, recurse: yes}
      watcher  = watchit 'fixtures', options, (event, file) ->
        return unless event in ['create', 'unlink', 'change']
        changed = yes
      fs.writeFileSync fixture '.meh'
      delay ->
        expect(changed).to.be(no)
        fs.unlinkSync fixture '.meh'
        delay ->
          expect(changed).to.be(no)
          watcher.close()
          done()
