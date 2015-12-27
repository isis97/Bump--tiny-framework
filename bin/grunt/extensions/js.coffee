module.exports =
  name: 'js'
  type: 'builder'
  fileExtension: 'js'
  npm: {
    "grunt-contrib-copy": "*"
  }
  transform: (core, input, output, inputPath, unitName, fileExtension) ->
    core.task unitName, 'copy',
      files: [
        expand: true
        cwd: "#{inputPath}/"
        src: ["./**/*.js"]
        dest: "#{output}"
      ]
