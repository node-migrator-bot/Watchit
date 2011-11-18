fs            = require 'fs'
{print}       = require 'util'
{spawn, exec} = require 'child_process'
watchit       = require 'watchit'

echo = (child) ->
  child.stdout.on 'data', (data) -> print data.toString()
  child.stderr.on 'data', (data) -> print data.toString()
  child

build = (callback) ->
  echo coffee = spawn 'coffee', ['-c', '-o', 'lib', 'src']
  coffee.on 'exit', (status) -> callback?() if status is 0

watch = (callback) ->
  # TODO
  build callback

task 'docs', 'Generate annotated source code with Docco', ->
  fs.readdir 'src', (err, contents) ->
    files = ("src/#{file}" for file in contents when /\.coffee$/.test file)
    echo docco = spawn 'docco', files
    docco.on 'exit', (status) -> callback?() if status is 0

task 'build', 'Compile CoffeeScript source files', ->
  build()

task 'watch', 'Recompile CoffeeScript source files when modified', ->
  watch()

task 'test', 'Run the test suite (and re-run if anything changes)', ->
  nodeunit = null
  watch ->
    suiteNames = [
      'helpers'
      'retain'
      'include'
      'follow'
      'recurse'
    ]
    idx = 0
    do runNextTestSuite = ->
      suiteName = suiteNames[idx++]
      command = """
        {reporters} = require 'nodeunit';
        reporters.default.run ['#{suiteName}.coffee']
      """
      nodeunit?.kill()
      echo nodeunit = spawn 'coffee', ['-e', command], cwd: 'test'
      if idx is suiteNames.length
        setTimeout process.exit, 5000
      else
        setTimeout (-> runNextTestSuite()), 1000