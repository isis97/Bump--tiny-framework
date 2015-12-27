
path = require 'path'
AnsiConverter = require 'ansi-to-html'
Core = require './bin/grunt/core'

module.exports = (grunt) ->

  extraInfo = grunt.option "extra"
  if not extraInfo?
    extraInfo =
      targetPath: path.resolve('.')
  RelPath = extraInfo.targetPath || '.'
  core = new Core grunt, RelPath
  core.inject(extraInfo.runTask, extraInfo.runConfig)
