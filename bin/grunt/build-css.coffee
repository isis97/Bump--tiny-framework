module.exports = (grunt, core) ->
  grunt.registerTask "build-css", "Parses stylesheets files and build files", () ->
    core.prTaskNotify 'Building stylesheets...'

    grunt.config.set "less", {}
    if core.buildConfig.components.indexOf("css") == -1
      return true

    grunt.file.expand({cwd:"#{core.buildConfig.dirs.css}"}, "./*").forEach (dir) ->
      if core.buildConfig.only?
        if core.buildConfig.only != dir
          return false

      out = "#{core.buildConfig.dirs.outputClient}/#{dir}/bin/build.css"
      if dir == './index'
        out = "#{core.buildConfig.dirs.outputClient}/bin/build.css"
      core.runBuilder "#{core.buildConfig.dirs.css}/#{dir}/#{core.buildConfig.dirs.cssPostfix}", out
