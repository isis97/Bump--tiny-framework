module.exports = (grunt, core) ->
  grunt.registerTask "build-assets", "Builds required ASSETS", () ->
    core.prTaskNotify 'Building assets...'
    grunt.file.recurse "#{core.buildConfig.dirs.assets}", (abspath, rootdir, subdir, filename) ->
      if not grunt.file.exists "#{core.buildConfig.dirs.outputClient}/assets/#{subdir}/#{filename}"
        grunt.file.copy "#{abspath}", "#{core.buildConfig.dirs.outputClient}/assets/#{subdir}/#{filename}"
