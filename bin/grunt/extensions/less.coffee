module.exports =
  name: 'less'
  type: 'builder'
  fileExtension: 'less'
  npm: {
    "grunt-contrib-less": "*"
  }
  transform: (core, input, output, inputPath, unitName, fileExtension) ->
    fl = {}
    fl[output] = [ "#{input}" ]
    core.task unitName, 'less',
      options:
        compress: true
        yuicompress: true
        optimization: 2
      files: fl
