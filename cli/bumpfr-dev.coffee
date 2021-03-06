fs = require 'fs'
program = require 'commander'
utils = require './util/util'

program
  .option('-p, --path [path]', 'Specifies path where to find Bump! project', '.')
  .option('-dd, --harddebug', 'Enables hard level debugging of Bump! itself (for devs)', false)
  .option('-d, --debug', 'Enable debug mode', false)
  .option('-n, --dry', 'Enable dry-run mode (does not write any files)', false)
  .option('-v, --verbose', 'Generate a lot of debug info. Please use with --debug flag.', false)
  .option('-f, --force', 'Skip any fatal error (may be dangerous sometimes)', false)
  .parse(process.argv)

RelPath = utils.getRelPath program
buildConfig = utils.getBuildConfig RelPath

utils.spawnGruntCli RelPath, 'dev', {
  debug: program.debug || program.harddebug
  stack: program.debug || program.harddebug
  write: !program.dry && (!program.harddebug)
  verbose: program.verbose || program.harddebug
  force: program.force || program.harddebug
}
