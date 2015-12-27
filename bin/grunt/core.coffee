ProgressBar = require 'progress'
path = require 'path'
fs = require 'fs'

Function.prototype.clone = () ->
  that = this
  temp = () ->
    return that.apply @, arguments
  for key in this
    if @hasOwnProperty(key)
      temp[key] = @[key]
  return temp

class Core
  @grunt: null
  RelPath: "."
  rel: (location, defaultLocation="") ->
    return ((location||defaultLocation).replace /\[RelPath\]/ig, @RelPath)
  extensions: {}
  builders: {}
  watchifyStatus: false
  buildConfigLocation: "[RelPath]/build.json"
  serverProcess: null
  internalDependencies: {}
  buildConfig: {}
  buildConfigDefault: {
    only: null
    fast: false
    components: [ 'src', 'html', 'css', 'node' ]
    streightOutput: false
    htmlLog: false
    exportPackageJSON: true
    standaloneBundling: false
    serverPort: 3000
    dirs:
      lib: "[RelPath]/lib"
      libdist: "[RelPath]/lib_dist"
      output: "[RelPath]/dist"
      html: "[RelPath]/units"
      css: "[RelPath]/units"
      js: "[RelPath]/units"
      htmlPostfix: "./html"
      cssPostfix: "./css"
      jsPostfix: "./src"
      assets: "[RelPath]/assets"
      tmp: "[RelPath]/tmp"
      tmplib: "[RelPath]/tmp/lib"
      node: "[RelPath]/node"
      views: "[RelPath]/units"
      ###
      output: './dist'
      html: './html'
      css: './css'
      js: './src'
      assets: './assets'
      tmp: './tmp'
      tmplib: './tmp/lib'
      node: './node'
      views: './views'
      ###
    support: [ "css", "js", "html" ]
  }
  pb: null
  pbRefreshen: false
  htmlLog:
    begin: () ->
    end: () -> return true
    save: () ->
    html: () -> return ""
    clear: () ->
    append: (type, message) ->
    info: (message) ->
    error: (message) ->
    debug: (message) ->
    task: (message) ->
  loadExtension: (name) ->
    try
      mod = require name
    catch e
      @grunt.fail.fatal "Cannot load extension #{name} (no such file)"
      #throw e
    if (not mod?) or (not mod)
      @grunt.fail.fatal "Cannot load extension #{name} (invalid entry point)"
    @registerExtension mod
  parseTemplates: (path, output) ->
    files = @grunt.file.expand patterns
    for file in files
      @parseTemplateFile file, output
  parseTemplateFile: (path, output) ->
    contents = @grunt.file.read path
    c = @copyObj @buildConfig
    contents = @grunt.template.process contents, c
    @grunt.file.write output, contents
  loadExtensions: (dir) ->
    dirs = fs.readdirSync "./bin/grunt/#{dir}"
    dirs.forEach (d) =>
      loc = "#{dir}/#{d}"
      @loadExtension loc
  registerExtension: (extension) ->
    ext =
      name: extension.name || 'unknown'
      type: extension.type || ''
      npm: extension.npm || {}
    @extensions[ext.name] = ext
    if ext.type == 'builder'
      ext.fileExtension = extension.fileExtension || ''
      ext.init = extension.init || (() -> return false)
      ext.transform = extension.transform || (() -> return false)
      ext.init this
      @builders[ext.fileExtension] = ext
  requestExtensionModulesDeps: (o) ->
    for name, ext of @extensions
      if @supports name
        for task, version of ext.npm
          o[task] = version
    return o
  requestExtensionModules: () ->
    for name, ext of @extensions
      if @supports name
        for task, version of ext.npm
          @grunt.loadNpmTasks task
  escapeTaskName: (name) ->
    return name.replace /[^\dA-Za-z]/ig, "X"
  esapeTaskConf: (conf) ->
    econf = {}
    for k, v of conf
      econf[@escapeTaskName k] = v
    return econf
  taskGlob: (unit, name, conf) ->
    C = @copyConf (@esapeTaskConf conf)
    supervisorTaskName = @escapeTaskName("task#{@escapeTaskName(name)}-#{@escapeTaskName(unit)}".replace(/\./g, "-"))
    o = C
    @grunt.registerTask supervisorTaskName, "", () =>
      @grunt.config.set name, o
      @grunt.task.run name
    @grunt.task.run supervisorTaskName
  task: (unit, name, conf) ->
    C = @copyConf (@esapeTaskConf conf)
    supervisorTaskName = @escapeTaskName("task#{@escapeTaskName(name)}-#{@escapeTaskName(unit)}".replace(/\./g, "-"))
    o = {}
    o["#{unit}"] = C
    @grunt.registerTask supervisorTaskName, "", () =>
      @grunt.config.set name, o
      @grunt.task.run name
    @grunt.task.run supervisorTaskName
  runBuilder: (input, output) ->
    input = path.normalize(input).replace(/\\/g, "/")
    output = path.normalize(output).replace(/\\/g, "/")
    inputPathTokens = input.split('/')
    unitName = inputPathTokens[inputPathTokens.length-2]
    usedExt = ""
    usedBuilder = null
    usedInputPath = ""
    for name, builder of @builders
      searchedInputPath = input + "/" + unitName + "." + builder.fileExtension
      #@grunt.log.write input+"\n"
      #@grunt.log.write unitName+"\n"
      #@grunt.log.write searchedInputPath+"\n"
      if @grunt.file.exists searchedInputPath
        if usedBuilder
          @grunt.fail.fatal "Found multiple source entries for unit \"#{unitName}\""
        else
          usedInputPath = searchedInputPath
          usedBuilder = builder
          usedExt = builder.fileExtension
    if not usedBuilder
      @grunt.fail.fatal "Not found source entry for unit \"#{unitName}\""
    if not @supports usedBuilder.name
      @grunt.fail.fatal "The #{usedBuilder.name} builder is required by the #{unitName} unit, but it's not supported."
    usedBuilder.transform this, usedInputPath, output, input, unitName, usedExt
  loadModule: (name) ->
    #try
    mod = require "./#{name}"
    #catch e
    #  @grunt.fail.fatal "Cannot load module #{name} (no such file)"
    #  #throw e
    if (not mod?) or (not mod)
      @grunt.fail.fatal "Cannot load module #{name} (invalid entry point)"
    mod @grunt, this
  prTaskNew: () ->
    @pbRefreshen = true
    @pb = new ProgressBar 'Building... [:bar]  :current/:total (:percent)  :details',
      total: 8
      complete: '#'
      incomplete: ' '
      width: 20
    @pb.curr = 0
  prTaskNotify: (message) ->
    @htmlLog.task message
    @pb.tick
      details: message
  supports: (id) ->
    f = @buildConfig.support.indexOf(id) > -1
    return f
  supportsServerSide: () ->
    return (@supports 'node')
  internalDependenciesGen: () ->
    i = {
      "grunt-cli": "*"
      "bower": "*"
      "load-grunt-tasks": "*"
      #"grunt-bower-install": "*"
      #"grunt-bower-requirejs": "*"
      #"grunt-wiredep": "*"
      "grunt-bower-task": "*"
      "grunt-contrib-clean": "*"
      "grunt-contrib-copy": "*"
      "grunt-contrib-concat": "*"
      "grunt-prompt": "*"
      "factor-bundle": "*"
      "ansi-to-html": "*"
      "grunt-includes": "*"
      "grunt-contrib-connect": "*"
      "grunt-html-generator": "*"
      "grunt-contrib-watch": "*"
      "grunt-watchify": "*"
      "browserify": "*"
      "stringify": "*"
      "browserify-derequire": "*"
      "progress": "*"
      "grunt-browserify": "*"
      "uglifyify": "*"
      "grunt-contrib-uglify": "*"
      "grunt-jsmin-sourcemap": "*"
      "errorify": "*"
      "stripify": "*"
      "brfs": "*"
      "licensify": "*"
      "debowerify": "*"
      "grunt-inline-css": "*"
      "grunt-contrib-htmlmin": "*"
      "requirejs": "*"
      "grunt-import": "*"
    }
    return @requestExtensionModulesDeps(i)
    #i["mustache"] = "*" if @supports 'mustache'
    #i["grunt-mustache-render"] = "*" if @supports 'mustache'
    #i["grunt-contrib-less"] = "*" if @supports 'less'
    #i["grunt-contrib-sass"] = "*" if @supports 'sass'
    #i["grunt-contrib-stylus"] = "*" if @supports 'stylus'
    #i["grunt-contrib-coffee"] = "*" if @supports 'coffee'
    #i["grunt-typescript"] = "*" if @supports 'typescript'
    #return i
  copyConf: (o) ->
    return @copyConfR o, {}
  copyConfR: (o, r) ->
    if o instanceof Array
      r = [] if not r?
    else
      r = {} if not r?
    if (o instanceof Function) or (o.apply?)
      return o.clone()
    else if o instanceof Array
      i = 0
      for key in o
        r.push (@copyConfR(key, r[i]))
        ++i
      return r
    else if o instanceof String
      return o+""
    else if o instanceof Number
      return o+0
    else if o instanceof Object
      for key, val of o
        r[key] = @copyConfR(val, r[key])
      return r
    else
      return o
  copyObj: (o, r) ->
    r = {} if not r?
    if o instanceof Object
      for key, val of o
        r[key] = @copyObj(val)
      return r
    else
      return o
  importDefProps: (o, def) ->
    if o instanceof Array
      if o?
        return o
      return def
    if not (o instanceof Object)
      return o || def
    for key, val of def
      o[key] = @importDefProps(o[key], val)
    return o
  importBuildConfig: () ->
    @buildConfig = @grunt.file.readJSON @buildConfigLocation
    @buildConfig = @buildConfig || {}
    @buildConfig = @importDefProps @buildConfig, @buildConfigDefault
    if @supportsServerSide
      @buildConfig.dirs.outputClient = "#{@buildConfig.dirs.output}/htdocs"
      @buildConfig.dirs.outputServer = "#{@buildConfig.dirs.output}/bin"
    else
      @buildConfig.dirs.outputClient = "#{@buildConfig.dirs.output}"
      @buildConfig.dirs.outputServer = "#{@buildConfig.dirs.output}"
    @grunt.config.set "buildConfig", @buildConfig
    @grunt.log.debug("Using the following build configuration:\n"+JSON.stringify(@buildConfig, null, 2))
  exportPackageJSON: () ->
    baseExportsOverride = (require '../config').baseExportsOverride
    libExportsOrig = @buildConfig.libExports
    libExportsOrig = @copyObj(baseExportsOverride, libExportsOrig)
    libExports = {}
    for name, props of libExportsOrig
      exportPrototype = {}
      exportPrototype["#{@buildConfig.dirs.libdist}/js"] =        props.js if props.js?
      exportPrototype["#{@buildConfig.dirs.libdist}/css"] =       props.css if props.css?
      exportPrototype["#{@buildConfig.dirs.libdist}/js"] =        props.distjs if props.distjs?
      exportPrototype["#{@buildConfig.dirs.libdist}/css"] =       props.distcss if props.distcss?
      exportPrototype["#{@buildConfig.dirs.libdist}/fonts"] =     props.font if props.font?
      exportPrototype["#{@buildConfig.dirs.libdist}/img"] =       props.img if props.img?
      exportPrototype["#{@buildConfig.dirs.lib}/js"] =        props.js if props.js?
      exportPrototype["#{@buildConfig.dirs.lib}/js/map"] =   props.map if props.map?
      exportPrototype["#{@buildConfig.dirs.lib}/css"] =       props.css if props.css?
      exportPrototype["#{@buildConfig.dirs.lib}/fonts"] =     props.font if props.font?
      exportPrototype["#{@buildConfig.dirs.lib}/img"] =       props.img if props.img?
      exportPrototype["#{@buildConfig.dirs.lib}/js/lang"] =   props.lang if props.lang?
      exportPrototype["#{@buildConfig.dirs.lib}/less"] =      props.less if props.less?
      exportPrototype["#{@buildConfig.dirs.lib}/sass"] =      props.sass if props.sass?
      exportPrototype["#{@buildConfig.dirs.lib}/html"] =      props.html if props.html?
      exportPrototype["#{@buildConfig.dirs.lib}/jade"] =      props.jade if props.jade?
      exportPrototype["#{@buildConfig.dirs.lib}/dart"] =      props.dart if props.dart?
      exportPrototype["#{@buildConfig.dirs.lib}/ts"] =        props.ts if props.ts?
      exportPrototype["#{@buildConfig.dirs.lib}/cs"] =        props.cs if props.cs?
      libExports[name] = exportPrototype
    @internalDependencies = @internalDependenciesGen @buildConfig
    exportedJSON = {}
    exportedJSON._ = "JSON Package automatically generated by @grunt."
    exportedJSON.__ = "To enable custom package.json set exportPackageJSON to false in build config json."
    exportedJSON.exportsOverride = libExports
    exportedJSON.name = @buildConfig.name || "Unknown"
    exportedJSON.version = @buildConfig.version || "0.0.1"
    exportedJSON.description = @buildConfig.description || ""
    exportedJSON.license = @buildConfig.license if @buildConfig.license?
    exportedJSON.homepage = @buildConfig.homepage if @buildConfig.homepage?
    exportedJSON.bugs = @buildConfig.bugs if @buildConfig.bugs?
    exportedJSON.keywords = @buildConfig.keywords if @buildConfig.keywords?
    exportedJSON.contributors = @buildConfig.contributors if @buildConfig.contributors?
    exportedJSON.bin = @buildConfig.bin if @buildConfig.bin?
    exportedJSON.main = @buildConfig.main if @buildConfig.main?
    exportedJSON.files = @buildConfig.files if @buildConfig.files?
    exportedJSON.man = @buildConfig.man if @buildConfig.man?
    exportedJSON.directories = @buildConfig.directories if @buildConfig.directories?
    exportedJSON.repository = @buildConfig.repository if @buildConfig.repository?
    exportedJSON.scripts = @buildConfig.scripts if @buildConfig.scripts?
    exportedJSON.config = @buildConfig.config if @buildConfig.config?
    exportedJSON.peerDependencies = @buildConfig.peerDependencies if @buildConfig.peerDependencies?
    exportedJSON.bundledDependencies = @buildConfig.bundledDependencies if @buildConfig.bundledDependencies?
    exportedJSON.optionalDependencies = @buildConfig.optionalDependencies if @buildConfig.optionalDependencies?
    exportedJSON.engines = @buildConfig.engines if @buildConfig.engines?
    exportedJSON.engineStrict = @buildConfig.engineStrict if @buildConfig.engineStrict?
    exportedJSON.os = @buildConfig.os if @buildConfig.os?
    exportedJSON.cpu = @buildConfig.cpu if @buildConfig.cpu?
    exportedJSON.preferGlobal = @buildConfig.preferGlobal if @buildConfig.preferGlobal?
    exportedJSON.private = @buildConfig.private if @buildConfig.private?
    exportedJSON.publishConfig = @buildConfig.publishConfig if @buildConfig.publishConfig?
    exportedJSON.author = @buildConfig.author if @buildConfig.author?
    oInternalDeps = {}
    #TODO: REPAIR oInternalDeps = @copyObj(@internalDependencies)
    exportedJSON.dependencies = @importDefProps oInternalDeps, @buildConfig.npm
    for key, val of exportedJSON.dependencies
      if @internalDependencies[key]?
        exportedJSON.dependencies[key] = undefined
        if not exportedJSON.devDependencies?
          exportedJSON.devDependencies = {}
        exportedJSON.devDependencies[key] = val
    if not @grunt.file.exists (@rel "[RelPath]/package.json")
      @grunt.log.ok "Package.json file was automatically created."
    @grunt.file.write (@rel "[RelPath]/package.json"), JSON.stringify(exportedJSON, null, 4)
    exportedJSON.dependencies = @buildConfig.bower
    exportedJSON.devDependencies = undefined
    @grunt.file.write (@rel "[RelPath]/bower.json"), JSON.stringify(exportedJSON, null, 4)
  deinit: () ->
    @pb.curr = 7
    @pb.tick 0,
        details: "Done."
    @prTaskNew()
  init: (grunt) ->
    @grunt = grunt if grunt?
    @htmlLog.clear()
    @htmlLog.begin()
    if @grunt.config.get("buildConfig")?
      @buildConfig = grunt.config.get("buildConfig")
    else if @buildConfig?
      @grunt.config.set "buildConfig", @buildConfig
    else
      @importBuildConfig()
    @grunt.log.debug "Currently used build setup:\n"+JSON.stringify(@buildConfig, null, 2)
    @exportPackageJSON() if @buildConfig.exportPackageJSON
    @grunt.log.debug "Currently used build setup:\n"+JSON.stringify(@buildConfig, null, 2)
  constructor: (@grunt, @RelPath) ->
    for k, v of @buildConfigDefault.dirs
      @buildConfigDefault.dirs[k] = (@rel v, "[RelPath]/#{k.toString()}")
    @buildConfigLocation = (@rel @buildConfigLocation, "[RelPath]/package.json")
    @importBuildConfig()
    if (not @buildConfig) or (not @buildConfig?)
      @grunt.fail.fatal "Problem with loading build configuration (INTERNAL ERROR)."
    @exportPackageJSON() if @buildConfig.exportPackageJSON
    if not @grunt.file.exists "node_modules/"
      @grunt.fail.fatal "Node dependencies are not installed. Please use \"npm install .\" firstly."
    htmlLogOuts = []
    @grunt.file.expand({cwd:"#{@buildConfig.dirs.html}"}, "./*").forEach (dir) =>
      out = "#{@buildConfig.dirs.outputClient}/#{dir}/#{dir}.html"
      if dir == './index'
        out = "#{@buildConfig.dirs.outputClient}/#{dir}.html"
      htmlLogOuts.push out
    if @buildConfig.htmlLog
      @htmlLog =
        wasError: false
        on: false
        log: []
        header: "<!DOCTYPE html><html><head><title>ThePickGame</title><meta http-equiv=\"refresh\" content=\"1\"></head><body style=\"background-color:#001f3f;\">"
        footer: "</body></html>"
        begin: () ->
          @on = true
          @wasError = false
        end: () ->
          @on = false
          @save()
          return not @wasError
        save: () ->
          for loc in htmlLogOuts
            @saveTo loc
        saveTo: (path) ->
          @grunt.file.write path, @html()
        html: () ->
          content = ""
          for item in @log
            if item.type == 'error'
              content += "<b><u>#{item.content}</u></b><br>"
            else if item.type == 'task'
              content += "<div style=\"background-color:#111111;color:white;\">#{item.content}</div><br>"
            else
              content += "#{item.content}<br>"
          return "#{@header}
          #{content}
          #{@footer}"
        clear: () ->
          @log = []
        append: (type, message) ->
          if not @on
            return
          if not message?
            return
          conv = new AnsiConverter()
          m = message
          m = conv.toHtml message
          @log.push
            type: type
            content: m
          @save()
        info: (message) -> @append 'info', message
        error: (message) ->
          @wasError = true
          @append 'error', message
        debug: (message) -> @append 'debug', message
        task: (message) -> @append 'task', message

    @grunt.echo = @grunt.log.write
    @gruntLogWriteln = @grunt.log.writeln
    @gruntLogError = @grunt.log.error

    if (not @buildConfig.streightOutput) or false
      #TODO:REAPIR the IF condition!
      @grunt.log.header = (header) ->
      @grunt.log.write = (message) ->
      @grunt.log.subhead = (message) ->
      @grunt.log.writeln = (message) =>
        if not message?
          return {
            success: () ->
          }
        if not message.indexOf?
          return {
            success: () ->
          }
        if (message.indexOf('arning')>-1) or (message.indexOf('rror')>-1)
          return @gruntLogWriteln(message)
        return {
          success: () ->
        }
      @grunt.fail.warn = (message) =>
        @gruntLogWriteln "\n" if pbRefreshen
        pbRefreshen = false
        @grunt.echo "[WARN]  "['yellow']
        @gruntLogError message
      @grunt.fail.fatal = (message) =>
        @gruntLogWriteln "\n" if pbRefreshen
        pbRefreshen = false
        @grunt.echo "[ERROR]  "['red']
        @gruntLogError message
      @grunt.log.error = (message) =>
        @gruntLogWriteln "\n" if pbRefreshen
        pbRefreshen = false
        @grunt.echo "[ERROR]  "['red']
        @gruntLogError message
      @grunt.log.errorlns = (message) =>
        @gruntLogWriteln "\n" if pbRefreshen
        pbRefreshen = false
        @grunt.echo "[ERROR]  "['red']
        @gruntLogError message
      @grunt.log.ok = (message) ->
      @grunt.log.oklns = (message) ->

    if @buildConfig.htmlLog
      @grunt.log.write ">> Using html log mode"
      @grunt.__echo = @grunt.echo
      @grunt.log.__write = @grunt.log.write
      @grunt.log.__writeln = @grunt.log.writeln
      @grunt.log.__error = @grunt.log.error
      @grunt.log.__errorlns = @grunt.log.errorlns
      @grunt.log.__ok = @grunt.log.ok
      @grunt.log.__oklns = @grunt.log.oklns
      @grunt.fail.__warn = @grunt.fail.warn
      @grunt.echo = (message) ->
        htmlLog.info message
        @grunt.__echo message
      @grunt.log.write = (message) ->
        if message?
          if (message.indexOf('arning')>-1) or (message.indexOf('rror')>-1)
            htmlLog.error message
          else
            htmlLog.info message
        @grunt.log.__write message
      @grunt.log.writeln = (message) ->
        if message?
          if (message.indexOf('arning')>-1) or (message.indexOf('rror')>-1)
            htmlLog.error message
          else
            htmlLog.info message
        @grunt.log.__writeln message
      @grunt.fail.warn = (message) ->
        htmlLog.error message
        @grunt.fail.__warn message
      @grunt.log.error = (message) ->
        htmlLog.error message
        @grunt.log.__error message
      @grunt.log.errorlns = (message) ->
        htmlLog.error message
        @grunt.log.__errorlns message
      @grunt.log.ok = (message) ->
        htmlLog.info message
        @grunt.log.__ok message
      @grunt.log.oklns = (message) ->
        htmlLog.info message
        @grunt.log.__oklns message
    @prTaskNew()
  getUnitsList: () ->
    arr = []
    arr1 = @grunt.file.expand({cwd:"#{@buildConfig.dirs.css}"}, "./*")
    arr2 = @grunt.file.expand({cwd:"#{@buildConfig.dirs.html}"}, "./*")
    arr3 = @grunt.file.expand({cwd:"#{@buildConfig.dirs.js}"}, "./*")
    arr = arr
    .concat( arr1 )
    .concat( arr2 )
    .concat( arr3 )
    units = {}
    arr.forEach((item) ->
      if not units[item]?
        i = {
          css: false
          html: false
          src: false
        }
        i.css = true if arr1.indexOf(item) != -1
        i.html = true if arr2.indexOf(item) != -1
        i.src = true  if arr3.indexOf(item) != -1
        i.name = item
        i.name += " [missing css source]" if not i.css
        i.name += " [missing html source]" if not i.html
        i.name += " [missing src source]"  if not i.src
        i.checked = false
        i.value = item
        units[item] = i
    )
    unitsPlain = []
    for k,v of units
      v.id = k
      unitsPlain.push v
    return unitsPlain
  inject: (command, exprops) ->
    grunt = @grunt
    core = @

    grunt.registerTask "deinit", "Deinit build", () -> core.deinit()
    grunt.registerTask "init", "Init build", () -> core.init(grunt)

    grunt.event.on 'watch', (action, filepath, target) ->
      if gruntLogWriteln?
        gruntLogWriteln "\n> Dynamically rebuilding..."
      fl = filepath.split '/'
      category = fl[0]
      unit = fl[1]
      core.buildConfig.only = null #"./#{unit}"
      core.buildConfig.fast = false
      if category == 'views'
        category = 'html'
      #core.buildConfig.components = [ category ]
      grunt.config.set "core.buildConfig", core.buildConfig
      return true

    grunt.initConfig
      pkg: grunt.file.readJSON (@rel "[RelPath]/package.json")
      watch:
        files: [
          "#{core.buildConfig.dirs.assets}/**"
          "#{core.buildConfig.dirs.html}/**"
          "#{core.buildConfig.dirs.css}/**"
          "#{core.buildConfig.dirs.js}/**"
          "#{core.buildConfig.dirs.node}/**"
          "#{core.buildConfig.dirs.views}/**"
        ]
        tasks: [ 'build-dev' ]
        options:
          nospawn: true
      clean: [
        "#{core.buildConfig.dirs.tmplib}/**/*", "#{core.buildConfig.dirs.tmplib}"
        "#{core.buildConfig.dirs.tmp}/**/*", "#{core.buildConfig.dirs.tmp}"
        "#{core.buildConfig.dirs.output}/**/*", "#{core.buildConfig.dirs.output}"
      ]
      connect:
        server:
          options:
            port: core.buildConfig.serverPort,
            base: "#{core.buildConfig.dirs.outputClient}"
            keepalive: false
      prompt:
        newUnit:
          options:
            questions: [
              config: 'newUnitName'
              type: 'input'
              message: 'Enter the new unit name: '
              validate: (value) ->
                if grunt.file.isDir("#{core.buildConfig.dirs.html}/#{value}") || grunt.file.isDir("#{core.buildConfig.dirs.css}/#{value}") || grunt.file.isDir("#{core.buildConfig.dirs.js}/#{value}")
                  return "The #{value} unit already exists!"
                if value.length < 3
                  return "The unit name must be at least 3 letters length!"
                if !((value[0] >= 'a' && value[0] <= 'z') || (value[0] >= 'A' && value[0] <= 'Z'))
                  return "The unit name must begin with a latin letter."
                return true
              filter: (value) ->
                value = value.replace(" ", "_")
                value = value.replace(/\n/g, "")
                value = value.replace(/\t/g, "_")
                value = value.replace(/\r/g, "")
                value = value.replace(/\./g, ".")
                return value
            ]
        removeUnit:
          options: {}
        viewUnits:
          options: {}

    core.loadModule 'run-utils'
    core.loadModule 'run-server'
    core.loadModule 'build-src'
    core.loadModule 'build-server'
    core.loadModule 'build-assets'
    core.loadModule 'build-html'
    core.loadModule 'build-css'
    core.loadModule 'build-compressor'
    core.loadExtensions './extensions'

    #grunt.loadNpmTasks 'grunt-bower-install'
    #grunt.loadNpmTasks 'grunt-browserify'
    #grunt.loadNpmTasks 'grunt-prompt'
    #grunt.loadNpmTasks 'grunt-watchify'
    try
      require('load-grunt-tasks')(grunt)
    catch e
    require('./tasks/bowertaskwire')(grunt, core)

    ###
    grunt.loadNpmTasks 'grunt-contrib-concat'
    grunt.loadNpmTasks 'grunt-contrib-copy'
    grunt.loadNpmTasks 'grunt-watchify'
    grunt.loadNpmTasks 'grunt-contrib-connect'
    grunt.loadNpmTasks 'grunt-prompt'
    grunt.loadNpmTasks 'grunt-contrib-clean'
    grunt.loadNpmTasks 'grunt-html-generator'
    grunt.loadNpmTasks 'grunt-contrib-uglify'
    grunt.loadNpmTasks 'grunt-contrib-watch'
    grunt.loadNpmTasks 'grunt-browserify'
    grunt.loadNpmTasks 'grunt-inline-css'
    grunt.loadNpmTasks 'grunt-contrib-htmlmin'
    grunt.loadNpmTasks 'grunt-wiredep'
    ###


    core.requestExtensionModules()

    grunt.registerTask 'lazy-load', 'Load lazy modules/tasks', () ->

    grunt.registerTask 'dev-server', [
      'lazy-load',
      'run-server',
      'watch'
    ]

    grunt.registerTask 'dev', [
      'lazy-load',
      'build-dev',
      'dev-server'
    ]

    grunt.registerTask 'install', [
      'lazy-load',
      'init',
      'update-deps',
      'deinit'
    ]

    grunt.registerTask 'build-dev', [
      'lazy-load',
      'init',
      'build-css',
      'build-src',
      'build-html',
      'build-assets',
      'build-src-server',
      'build-compressor',
      'deinit'
    ]
    grunt.registerTask 'build', ['build-dev']

    if exprops?
      grunt.config.merge exprops
    if command?
      grunt.registerTask 'default', [command]
    else
      grunt.registerTask 'default', ['build-dev']
    #grunt.task.clearQueue()
    #grunt.task.run(['default'])

module.exports = Core
