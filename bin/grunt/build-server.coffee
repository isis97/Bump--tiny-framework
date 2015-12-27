module.exports = (grunt, core) ->
  grunt.registerTask "build-src-server", "Parses SERVER-SIDE files and build files", () ->
    core.prTaskNotify 'Preparing server side resources...'
    if core.buildConfig.components.indexOf("node") != -1
      if core.supports 'node'
        if grunt.file.exists "#{core.buildConfig.dirs.node}/main.coffee"
          taskCoffee = {}
          taskCoffee["node"] = {
            src: ["**/*.coffee"]
            cwd: "#{core.buildConfig.dirs.node}"
            dest: "#{core.buildConfig.dirs.outputServer}/node/"
            expand: true
            ext: '.js'
            options: {}
            bare: true
          }
          if core.supports 'coffee'
            grunt.config.set "coffee", taskCoffee
            grunt.task.run "coffee"
          else
            grunt.fail.fatal "The support for COFFEE has been disabled, the node.js scripts requested it."
        else if grunt.file.exists "#{core.buildConfig.dirs.node}/main.js"
          taskJavascript = {}
          taskJavascript[dir] = {
            files: [
              expand: true
              cwd: "#{core.buildConfig.dirs.node}/"
              src: ["./**"]
              dest: "#{core.buildConfig.dirs.outputServer}/node/"
            ]
          }
          grunt.config.set "copy", taskJavascript
          grunt.task.run "copy"
        else
          grunt.fail.fatal "The node.js server side entry point does not exist (#{core.buildConfig.dirs.node}/main.js)"
