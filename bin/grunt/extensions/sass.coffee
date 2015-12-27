module.exports =
  name: 'sass'
  type: 'builder'
  fileExtension: 'sass'
  npm: {
    "grunt-sass": ">=0.9.2"
  }
  transform: (core, input, output, inputPath, unitName, fileExtension) ->
    fl = {}
    fl["#{output}"] = [ "#{input}" ]
    console.log output
    console.log "\nUNIT NAME = "+unitName+"\n"
    core.task unitName, 'sass',
      files: fl
