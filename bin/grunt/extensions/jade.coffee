module.exports =
  name: 'jade'
  type: 'builder'
  fileExtension: 'jade'
  npm: {
    "grunt-contrib-jade": "*"
  }
  transform: (core, input, output, inputPath, unitName, fileExtension) ->
    data = core.buildConfig
    if core.grunt.file.exists "#{core.buildConfig.dirs.views}/#{unitName}.json"
      data = core.copyObj core.buildConfig, core.grunt.file.readJSON("#{core.buildConfig.dirs.views}/#{unitName}.json")
    fl = {}
    fl["#{output}/#{unitName}.html"] = "#{input}"
    core.task unitName, 'jade',
      files: fl
      options:
        data: (dest, src) ->
          return data
