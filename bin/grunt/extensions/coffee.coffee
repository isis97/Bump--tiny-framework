module.exports =
  name: 'coffee'
  type: 'builder'
  fileExtension: 'coffee'
  npm: {
    "grunt-contrib-coffee": "*"
  }
  transform: (core, input, output, inputPath, unitName, fileExtension) ->
    core.task unitName, 'coffee',
      src: ["./**/*.coffee"]
      cwd: "#{inputPath}"
      dest: "#{output}"
      expand: true
      ext: '.js'
      options: {}
      bare: true
