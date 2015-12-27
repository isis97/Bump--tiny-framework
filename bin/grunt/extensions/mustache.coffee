module.exports =
  name: 'mustache'
  type: 'builder'
  fileExtension: 'mustache'
  npm: {
    "grunt-mustache-render": "*"
  }
  transform: (core, input, output, inputPath, unitName, fileExtension) ->
    core.task unitName, 'mustache_render',
      options:
        partial_finder: (name) ->
          name = "#{core.buildConfig.dirs.html}/#{unitName}/#{name}"
          if core.grunt.file.exists "#{name}.mustache"
              name = "#{name}.mustache"
          else if core.grunt.file.exists "#{name}.html"
            name = "#{name}.html"
          if not core.grunt.file.exists name
            core.grunt.log.error "Mustache partial does not exist! #{name}\n"
            return ""
          core.grunt.log.debug "Importing mustache partial from #{name}\n"
          return core.grunt.file.read(name)
      files: [
        {
          data: "./package.json"
          src: "#{input}"
          dest: "#{output}/#{unitName}.html"
        }
      ]
