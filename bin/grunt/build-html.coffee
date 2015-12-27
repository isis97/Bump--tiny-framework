path = require 'path'

module.exports = (grunt, core) ->
  grunt.registerTask "build-html", "Parses HTML templates and build files", () ->
    core.prTaskNotify 'Building html files...'

    headName = ""
    if (not core.supports 'requirejs') and (not core.supports 'amd')
      headName = "global_head.html"
    else
      headName = "global_head_amd.html"
    headNameCache = []
    headNameOrig = "./bin/#{headName}"

    htmlJoinFilesListCount = 1
    htmlJoinFilesList = {}
    htmlWiredList = {
        src: []
    }
    grunt.file.expand({cwd:"#{core.buildConfig.dirs.html}"}, "./*").forEach (dir) ->

      if core.buildConfig.only?
        if core.buildConfig.only != dir
          return false
      rootPath = "../bin/"
      outAMDCommon = "#{core.buildConfig.dirs.outputClient}/#{dir}/bin/global_requirejs_common.js"
      out = "#{core.buildConfig.dirs.outputClient}/#{dir}/#{dir}.html"
      common = "../bin/common.js"
      if dir == './index'
        rootPath = "./bin/"
        out = "#{core.buildConfig.dirs.outputClient}/#{dir}.html"
        outAMDCommon = "#{core.buildConfig.dirs.outputClient}/bin/global_requirejs_common.js"
        common = "./bin/common.js"
      if core.buildConfig.standaloneBundling
        jsFiles = ["./bin/build.js"]
      else
        jsFiles = [common, "./bin/build.js"]
      jsFiles.unshift "#{rootPath}common_amd.js"

      headNameCacheL = "./bin/cache/#{dir}/#{headName}"
      headNameCache.push headNameCacheL
      headParsedVariabl = {
        rootPath: rootPath
      }
      headParsedContent = grunt.template.process grunt.file.read(headNameOrig), {
        data: headParsedVariabl
      }
      grunt.file.write headNameCacheL, headParsedContent

      htmlWiredList.src.push out
      htmlJoinFilesList["buildHTMLUnit#{htmlJoinFilesListCount}"] =
        options:
          output: out
          minify: false
        files:
          title: '<%= pkg.name %>'
          body: ["#{core.buildConfig.dirs.tmp}/#{dir}/#{dir}.final.html"]
          head: ["#{headNameCacheL}"]
          js: jsFiles
          css: []

      core.runBuilder "#{core.buildConfig.dirs.html}/#{dir}/#{core.buildConfig.dirs.htmlPostfix}", "#{core.buildConfig.dirs.tmp}/#{dir}/"
      core.grunt.registerTask "parseHTMLTemplate#{dir}", "Parses files as grunt template.", () ->
        core.parseTemplateFile "#{core.buildConfig.dirs.tmp}/#{dir}/#{dir}.html", "#{core.buildConfig.dirs.tmp}/#{dir}/#{dir}.final.html"
      core.grunt.task.run "parseHTMLTemplate#{dir}"
      ++htmlJoinFilesListCount

    extend = (obj, mixin) ->
      obj[name] = method for name, method of mixin
      obj
    o = extend {
      options:
        root: '.'
    }, htmlJoinFilesList
    #grunt.config.set 'html-generator', o
    #grunt.config.set 'wiredep', htmlWiredList

    core.prTaskNotify 'Bundling HTML...'
    #if core.htmlLog.end()
    core.taskGlob "globtask-build-html", "html-generator", o
    if core.supports 'wiredep'
      #TODO: REPAIR
      core.taskGlob "globtask-build-html", "bowertaskwire", htmlWiredList
