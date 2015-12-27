path = require 'path'

module.exports = (grunt, core) ->
    normPath = (p) ->
        p = path.normalize(p)
        p = p.replace /\\/g, "/"
        p = "./" + p
        return p
    doWithAsset = (pattern, fn) ->
        glob = "./#{pattern}"
        cwd = "#{core.buildConfig.dirs.libdist}/"
        grunt.file.expand({
          cwd: cwd
        }, glob).forEach (dir) ->
          A = path.normalize(cwd).replace(/\\/g, "/")
          B = path.normalize(dir).replace(/\\/g, "/")
          C = path.normalize(path.dirname(dir)).replace(/\\/g, "/")
          D = path.normalize(path.basename(dir)).replace(/\\/g, "/")
          fn(A, B, C, D)
    sources = {
        js: []
        css: []
        fonts: []
        img: []
    }

    doWithAsset 'js/**/*.js', (cwd, loc, dir, name) ->
        sources.js.push path.basename(loc)
        #console.log("Bower-task-wire: Discovered JS source: #{loc}")
    doWithAsset 'css/**/*.css', (cwd, loc, dir, name) ->
        sources.css.push path.basename(loc)
        #console.log("Bower-task-wire: Discovered CSS source: #{loc}")
    doWithAsset 'fonts/**/*.*', (cwd, loc, dir, name) ->
        sources.fonts.push path.basename(loc)
        #console.log("Bower-task-wire: Discovered FONT source: #{loc}")
    doWithAsset 'img/**/*.*', (cwd, loc, dir, name) ->
        sources.img.push path.basename(loc)
        #console.log("Bower-task-wire: Discovered IMG source: #{loc}")

    grunt.task.registerMultiTask 'bowertaskwire', 'Wire bower-task dependencies.', () ->
        taskData = @data
        taskTargetName = @target
        taskSrcs = taskData



        depsDecl = null
        wireDeps = null
        clearWireDep = () ->
            depsDecl = {
                js: ""
                css: ""
            }
            wireDeps = {
                js: []
                css: []
            }
        addWireDep = (cat, str) ->
            wireDeps[cat].push str
        exportWireDep = () ->
            depsDecl = {
                js: wireDeps.js.join('\n')
                css: wireDeps.css.join('\n')
            }
        clearWireDep()

        wire = (outFilePath) ->
            console.log "Bower-task-wire: Wired dependencies in #{outFilePath}!"
            # (.*)(wire:css)((.|\s)*)(\n.*endwire:css)
            # (.*)(wire:js)((.|\s)*)(\n.*endwire:js)
            # $1$2\n#{depsDecl.css}$5
            # $1$2\n#{depsDecl.js}$5

            matcherJs = null
            matcherCss = null
            replacerJs = null
            replacerCss = null


            if outFilePath.indexOf(".html")>-1 or outFilePath.indexOf(".htm")>-1
                console.log "USE HTML/HTM REPLACER"
                matcherJs = /(\s*<!-- wire:js -->)\n((.|\s)*?)\n(\s*<!-- endwire:js -->)/gm
                replacerJs = "$1\n#{depsDecl.js}\n$4"
                matcherCss = /(\s*<!-- wire:css -->)\n((.|\s)*?)\n(\s*<!-- endwire:css -->)/gm
                replacerCss = "$1\n#{depsDecl.css}\n$4"
            else if outFilePath.indexOf(".js")>-1
                console.log "USE JS REPLACER"
                matcherJs = "/* wire:js */"
                replacerJs = "#{depsDecl.js}"
                matcherCss = "/* wire:css */"
                replacerCss = "#{depsDecl.css}"
            else
                console.log("Bower-task-wire: I don't know how to inject deps in this type of file (is it not .html/.htm/.js?)")

            outFileContents = grunt.file.read outFilePath
            outFileContents = outFileContents.replace matcherJs, replacerJs
            outFileContents = outFileContents.replace matcherCss, replacerCss
            console.log depsDecl.js
            console.log outFileContents
            grunt.file.write outFilePath, outFileContents
        wireAll = (fn) ->
            console.log "Bower-task-wire: Wiring all..."
            for p in taskSrcs
                console.log "Bower-task-wire: Wire #{JSON.stringify(p, null, 2)}"
                fn(p)

        genModPath = (p) ->
            return p.replace /(.*)(\.js)/g, "$1"

        genModName = (p) ->
            bn = path.basename(p)
            nameTokens = bn.split('.')
            name = nameTokens[0]
            ext = nameTokens[nameTokens.length-1]
            return "#{name}"

        wireStatic = (outFilePath) ->
            relPathHtdocs = path.relative(path.dirname(outFilePath), "#{core.buildConfig.dirs.outputClient}/bin")
            relPathHtdocs = normPath relPathHtdocs
            relLib = normPath (relPathHtdocs+"/lib")
            clearWireDep()
            for remoteName, remoteAdress of core.buildConfig.remote
              addWireDep('js', "<script src=\"#{remoteAdress}\" type=\"text/javascript\"></script>")
            for js in sources.js
                jsSrcPath = normPath(relLib + "/js/" + js)
                addWireDep('js', "<script src=\"#{jsSrcPath}\" type=\"text/javascript\"></script>")
            for css in sources.css
                cssSrcPath = normPath(relLib + "/css/" + css)
                addWireDep('css', "<link rel=\"stylesheet\" type=\"text/css\" href=\"#{cssSrcPath}\">")
            exportWireDep()
            wire(outFilePath)

        wireRequirejs = (outFilePath) ->
            relPathHtdocs = path.relative(path.dirname(outFilePath), "#{core.buildConfig.dirs.outputClient}/bin")
            relPathHtdocs = normPath relPathHtdocs
            relLib = normPath (relPathHtdocs+"/lib")
            clearWireDep()
            i = 0
            for remoteName, remoteAdress of core.buildConfig.remote
              removeCorAdress = remoteAdress.substring( 0, remoteAdress.lastIndexOf( ".js" ) )
              addWireDep('js', "\"#{remoteName}\": \"#{removeCorAdress}\",")
            for js in sources.js
              jsMod = genModName(js)
              jsSrcPath = genModPath(normPath(relLib + "/js/" + js))
              comma = ""
              if i != sources.js.length-1
                  comma = ","
              addWireDep('js', "\"#{jsMod}\": \"#{jsSrcPath}\"#{comma}")
              ++i
            for css in sources.css
              cssSrcPath = normPath(relLib + "/css/" + css)
              addWireDep('css', "<link rel=\"stylesheet\" type=\"text/css\" href=\"#{cssSrcPath}\">")
            exportWireDep()
            wire(outFilePath)

        if core.supports 'wiredep'
            if (not core.supports 'requirejs') and (not core.supports 'amd')
                console.log "[grunttaskwire] Wiring bower dependencies from lib dist (STATIC)"
                wireAll(wireStatic)
            else if (core.supports 'requirejs') or (core.supports 'amd')
                console.log "[grunttaskwire] Wiring bower dependencies from lib dist (REQUIREJS)"
                wireAll(wireRequirejs)
