watchit = require '../src/watchit'
fs = require 'fs'
path = require 'path'

delay = (func) -> setTimeout func, 50

exports['With follow, a moved file is watched'] = (test) ->
  try
    fs.unlinkSync 'fixtures/rat.test'
  try
    fs.unlinkSync 'fixtures/piedPiper.test'

  fs.writeFileSync 'fixtures/rat.test', 'First'
  changeCount = 0
  watchit 'fixtures/rat.test', follow: true, (event) ->
    changeCount++ if event is 'change'

  delay ->
    fs.writeFileSync 'fixtures/rat.test', 'Second'
    delay ->
      test.equal 1, changeCount
      fs.renameSync 'fixtures/rat.test', 'fixtures/piedPiper.test'
      test.ok !path.exists 'fixtures/rat.test'
      test.equal 'Second', fs.readFileSync('fixtures/piedPiper.test')
      fs.writeFileSync 'fixtures/piedPiper.test', 'Third'
      delay ->
        test.equal 2, changeCount
        fs.writeFileSync 'fixtures/rat.test', 'Back from the grave!'
        delay ->
          test.equal 2, changeCount
          test.done()

exports['With follow and retain, several files may become watched'] = (test) ->
  try
    fs.mkdirSync 'fixtures/chain'
  children = fs.readdirSync 'fixtures/chain'
  fs.unlinkSync path.join('fixtures/chain', child) for child in children

  fs.writeFileSync 'fixtures/chain/1.test', 'Fuzzlewit'
  successCount = 0
  changeCount = 0
  watchit 'fixtures/chain/1.test', follow: true, retain: true, (event) ->
    successCount++ if event is 'success'
    changeCount++ if event is 'change'

  delay ->
    test.equal 1, successCount
    fs.renameSync 'fixtures/chain/1.test', 'fixtures/chain/2.test'
    delay ->
      test.equal 1, successCount
      test.equal 0, changeCount
      fs.writeFileSync 'fixtures/chain/1.test', 'The Replacement'
      delay ->
        test.equal 2, successCount
        test.equal 0, changeCount
        test.done()
        return

      # fs.writeFileSync 'fixtures/chain/2.test', 'Chuzzlewit'
      # delay ->
      #   test.equal 2, successCount
      #   test.equal 1, changeCount
      #   test.done()
      #   return

      #   fs.writeFileSync 'fixtures/chain/2.test', 'Fizzbottom'
      #   delay ->
      #     test.equal 2, changeCount
      #     fs.renameSync 'fixtures/chain/2.test', 'fixtures/chain/3.test'
      #     fs.writeFileSync 'fixtures/chain/3.test', 'Ms. Frizzle'
      #     fs.writeFileSync 'fixtures/chain/2.test', 're-creating'
      #     fs.writeFileSync 'fixtures/chain/2.test', 'changing'
      #     delay ->
      #       test.equal 4, changeCount
      #       fs.renameSync 'fixtures/chain/1.test', 'fixtures/chain/4.test'
      #       fs.writeFileSync 'fixtures/chain/4.test', 'Snuffleupagus'
      #       delay ->
      #         test.equal 4, changeCount
      #       test.done()