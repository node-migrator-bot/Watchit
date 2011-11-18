{exec} = require 'child_process'
fs = require 'fs'

eventCount = 0
fs.watchFile 'foo.txt', interval: 0, -> eventCount++

touch = -> exec 'touch foo.txt'

count = 0
repeat = ->
  setTimeout (->
    touch()
    touch()
    count++
    if count is 5
      setTimeout (-> console.log eventCount), 100
    else
      repeat()
  ), 1

setTimeout repeat, 100