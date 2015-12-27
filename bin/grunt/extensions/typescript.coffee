module.exports =
  name: 'typescript'
  type: 'builder'
  fileExtension: 'ts'
  npm: {
    "grunt-typescript": "*"
  }
  transform: (core, input, output, inputPath, unitName, fileExtension) ->
    core.task unitName, 'typescript',
      src: ["#{input}/**/*.ts"]
      dest: "#{output}/#{unitName}.js"
