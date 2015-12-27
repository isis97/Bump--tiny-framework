module.exports =
  name: 'html'
  type: 'builder'
  fileExtension: 'html'
  npm: {
    "grunt-includes": "*"
  }
  transform: (core, input, output, inputPath, unitName, fileExtension) ->
    core.task unitName, 'includes',
      files: [
        src: "#{input}"
        dest: "#{output}"
        cwd: '.'
        flatten: true
        includePath: "#{inputPath}/"
        filenameSuffix: ".html"
        includeRegexp: /^(\s*)#import\s+[\["<](\S+)[\]">]\s*$/
      ]
      options:
        flatten: true
        includePath: "#{inputPath}/"
        filenameSuffix: ".html"
        includeRegexp: /^(\s*)#import\s+[\["<](\S+)[\]">]\s*$/
