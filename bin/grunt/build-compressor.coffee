module.exports = (grunt, core) ->
  grunt.registerTask "build-compressor", "Compress the final dist build", () ->
    core.prTaskNotify 'Compressing dist...'
    taskInlinecss = {
      dist:
        files: [{
          expand: true
          cwd: "#{core.buildConfig.dirs.outputClient}/"
          src: "./**/*.html"
          dest: "#{core.buildConfig.dirs.tmp}/semi_compression/"
        }]
    }
    taskHtmlmin = {
      dist:
        options:
          removeComments: true
          collapseWhitespace: true
          removeCommentsFromCDATA: true
          removeCDATASectionsFromCDATA: true
          collapseBooleanAttributes: true
          removeAttributeQuotes: true
          removeRedundantAttributes: true
          useShortDoctype: true
          removeEmptyAttributes: true
          removeScriptTypeAttributes: true
          removeStyleLinkTypeAttributes: true
          removeOptionalTags: true
          removeIgnored: true
          removeEmptyElements: true
          minifyJS: true
          minifyCSS: true
          minifyURLs: true
        files: [{
          expand: true
          cwd: "#{core.buildConfig.dirs.tmp}/semi_compression/"
          src: "./**/*.html"
          dest: "#{core.buildConfig.dirs.outputClient}_min/"
        }]
    }
    if core.supports 'min'
      copyAmds = {
        files: [{
          expand: true
          cwd: "#{core.buildConfig.dirs.outputClient}/"
          src: "./**/!(build).!(html)"
          dest: "#{core.buildConfig.dirs.outputClient}_min/"
        }]
      }
      if (core.supports 'requirejs') or (core.supports 'amd')
        #grunt.config.set "copy", copyAmds
        #grunt.task.run "copy"
        core.task "globtask-build-compressor-min", "copy", copyAmds
      #grunt.config.set "inlinecss", taskInlinecss
      #grunt.task.run "inlinecss"
      core.taskGlob "globtask-build-compressor", "inlinecss", taskInlinecss
      #grunt.config.set "htmlmin", taskHtmlmin
      #grunt.task.run "htmlmin"
      core.taskGlob "globtask-build-compressor", "htmlmin", taskHtmlmin
