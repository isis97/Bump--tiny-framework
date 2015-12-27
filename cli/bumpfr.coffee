fs = require 'fs'
program = require 'commander'
utils = require './util/util'
colors = require 'colors/safe'

config = {}
buildConfig = {}

try
  config = fs.readFileSync "#{__dirname}/package.json"
  config = JSON.parse config
catch e
  utils.fatal """Could not find pacakge.json - Bump! was installed incorrectly.
  Please reinstall Bump!
  If this error will be thrown again please provide issue information to framework authors.

  Error details:
  #{e.message}"""

program
  .version(config.version)
  .command('build [path]', 'Run build proccess')
  .command('install', 'Installs/updates project dependencies')
  .command('dev', 'Runs dev server with autoreload on local host')
  .command('newunit [name]', 'Creates new unit with given name')
  .command('removeunit [name]', 'Removes permamently an unit with given name')
  .command('list', 'Lists all units of a given Bump! project')
  .parse(process.argv)
