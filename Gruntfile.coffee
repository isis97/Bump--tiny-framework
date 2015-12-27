fs = require 'fs'

module.exports = (grunt) ->

  prependBumpScriptHeader = (path) ->
    content = fs.readFileSync path
    content = """#!/usr/bin/env node
      /*
      #
      # Bump framework (#{conf.name} #{conf.version})
      # Cli module by #{conf.author.name} (#{conf.author.site})
      #
      # license #{conf.license}
      #
      */

    """ + content + """

    /*
    #    #{conf.name} #{conf.version}
    */
    """
    fs.writeFileSync path, content
  prependBumpScriptHeaders = (paths) ->
    for path in paths
      prependBumpScriptHeader path

  conf = grunt.file.readJSON './package.json'
  grunt.initConfig
    coffee:
      bumpfr:
        files: [
          {
            expand: true
            cwd: './cli/'
            src: ['**/*.coffee']
            dest: './'
            ext: '.js'
          }
          './util/util.js': ['./util_src/util.coffee']
        ]
    uglify:
      options:
        mangle: false
      bumpfr:
        files: [
          {
            expand: true
            cwd: './'
            src: ['*.js']
            dest: './'
            ext: '.js'
          },
          './util/util.js': ['./util/util.js']
        ]


  grunt.registerTask 'bumpfr-gen', 'Generate headers for bumpfr.js', () ->
    prependBumpScriptHeaders grunt.file.expand('*.js')
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.registerTask 'default', ['coffee', 'uglify', 'bumpfr-gen']
