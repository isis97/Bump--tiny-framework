module.exports =
  name: 'stylus'
  type: 'builder'
  fileExtension: 'styl'
  npm: {
    "grunt-contrib-stylus": "*"
  }
  transform: (core, input, output, inputPath, unitName, fileExtension) ->
    fl = {}
    fl[output] = [ "#{input}" ]
    core.task unitName, 'stylus',
      files: fl
