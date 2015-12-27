process = require 'child_process'

module.exports = (grunt, core) ->
  grunt.registerTask "update-deps", "Updates all project dependencies", () ->
    log = process.execSync "npm install .", { encoding: 'utf8' }
    console.log log
    core.taskGlob "globtask-install-bower-deps-fl", "bower", {
      install:
        options:
          targetDir: "./"
          #layout: 'byType'
          layout: (type, component, source) ->
            return "./"+type
          install: true
          verbose: false
          copy: true
          cleanTargetDir: false
          cleanBowerDir: false
          bowerOptions:
            production: false
    }

  grunt.registerTask "remove", "Remove an unit", () ->
    grunt.config.set 'prompt.removeUnit', {
      options:
        questions: [
          config: 'removeUnitName'
          type: 'list'
          choices: core.getUnitsList()
          message: 'Enter a name of the unit to be removed PERMAMENTLY: '
        ]
    }
    grunt.task.run 'prompt:removeUnit'
    grunt.task.run 'removeUnit'

  grunt.registerTask "viewUnits", "View all available units", () ->
    grunt.echo " -- [Project units] -- \n"
    core.getUnitsList().forEach((unit) ->
        grunt.echo( " ==> "+"#{unit.value}"['green'].bold+"\n" )
    )

  grunt.registerTask "newUnit", "Creates new unit", () ->
    name = grunt.config.get('newUnitName')
    grunt.echo "Creating new empty unit: #{name}\n"
    grunt.file.mkdir "#{core.buildConfig.dirs.html}/#{name}/#{core.buildConfig.dirs.htmlPostfix}"
    if core.supports 'jade'
      grunt.file.write "#{core.buildConfig.dirs.html}/#{name}/#{core.buildConfig.dirs.htmlPostfix}/#{name}.jade", ''
    else
      grunt.file.write "#{core.buildConfig.dirs.html}/#{name}/#{core.buildConfig.dirs.htmlPostfix}/#{name}.html", ''
    grunt.file.mkdir "#{core.buildConfig.dirs.css}/#{name}/#{core.buildConfig.dirs.cssPostfix}"
    if core.supports 'less'
      grunt.file.write "#{core.buildConfig.dirs.css}/#{name}/#{core.buildConfig.dirs.cssPostfix}/#{name}.less", ''
    else if core.supports 'sass'
      grunt.file.write "#{core.buildConfig.dirs.css}/#{name}/#{core.buildConfig.dirs.cssPostfix}/#{name}.sass", ''
    else if core.supports 'stylus'
      grunt.file.write "#{core.buildConfig.dirs.css}/#{name}/#{core.buildConfig.dirs.cssPostfix}/#{name}.styl", ''
    else
      grunt.file.write "#{core.buildConfig.dirs.css}/#{name}/#{core.buildConfig.dirs.cssPostfix}/#{name}.css", ''
    grunt.file.mkdir "#{core.buildConfig.dirs.js}/#{name}/#{core.buildConfig.dirs.jsPostfix}"
    if core.supports 'coffee'
      grunt.file.write "#{core.buildConfig.dirs.js}/#{name}/#{core.buildConfig.dirs.jsPostfix}/#{name}.coffee", ''
    else
      grunt.file.write "#{core.buildConfig.dirs.js}/#{name}/#{core.buildConfig.dirs.jsPostfix}/#{name}.js", ''

  grunt.registerTask "removeUnit", "Removes an unit", () ->
    name = grunt.config.get('removeUnitName')
    grunt.echo "Removing existing unit: #{name}\n"
    grunt.file.delete("#{core.buildConfig.dirs.html}/#{name}") if grunt.file.exists "#{core.buildConfig.dirs.html}/#{name}"
    grunt.file.delete("#{core.buildConfig.dirs.css}/#{name}") if grunt.file.exists "#{core.buildConfig.dirs.css}/#{name}"
    grunt.file.delete("#{core.buildConfig.dirs.js}/#{name}") if grunt.file.exists "#{core.buildConfig.dirs.js}/#{name}"
    grunt.file.delete("#{core.buildConfig.dirs.outputClient}/#{name}") if grunt.file.exists "#{core.buildConfig.dirs.outputClient}/#{name}"

  grunt.registerTask 'new', [ 'prompt:newUnit', 'newUnit' ]
  grunt.registerTask 'view', [ 'viewUnits' ]
  grunt.registerTask 'list', [ 'viewUnits' ]
