module.exports =
  name: 'css'
  type: 'builder'
  fileExtension: 'css'
  npm: {
    "grunt-contrib-copy": "*"
  }
  transform: (core, input, output, inputPath, unitName, fileExtension) ->
    core.task unitName, 'copy',
      files: [
        src: ["#{inputPath}/**"]
        dest: output
      ]
