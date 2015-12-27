module.exports = (grunt, core) ->

    grunt.registerTask "build-src", "Parses JAVASCRIPT files and build files", () ->
      core.prTaskNotify 'Compiling javascript sources...'

      if core.buildConfig.components.indexOf("src") == -1
        return true
      fa = []
      faOut = []
      amdModSrcDirs = []
      amdModDestDirs = []
      amdModCwdDirs = []
      amdModEntrypoints = []
      amdModCommonEntrypoint = []
      obf = []
      obfOut = []
      grunt.file.expand({cwd:"#{core.buildConfig.dirs.js}"}, "./*").forEach (dir) ->
        dirName = dir.replace("./", "")
        if core.buildConfig.only?
          if core.buildConfig.only != dir
            return false

        outDir = "#{core.buildConfig.dirs.outputClient}/#{dir}/bin"
        if dir == './index'
          outDir = "#{core.buildConfig.dirs.outputClient}/bin"
        out = "#{outDir}/build.js"
        fa.push("#{core.buildConfig.dirs.tmplib}/#{dir}/#{dir}.js")
        amdModDestDirs.push("#{outDir}/")
        amdModCwdDirs.push("#{core.buildConfig.dirs.tmplib}/#{dir}/")
        amdModSrcDirs.push("**/*.*")
        amdModEntrypoints.push("#{dirName}")
        amdModCommonEntrypoint.push "#{core.buildConfig.dirs.outputClient}/bin/common_amd.js"
        faOut.push(out)
        core.runBuilder "#{core.buildConfig.dirs.js}/#{dir}/#{core.buildConfig.dirs.jsPostfix}", "#{core.buildConfig.dirs.tmplib}/#{dir}/"

      core.prTaskNotify 'Building sources...'

      core.task "globtask-copy-lib-dist", "copy", {
        files: [{
          expand: true
          cwd: "./lib_dist/"
          src: "./**/*.*"
          dest: "#{core.buildConfig.dirs.outputClient}/bin/lib/"
        }]
      }

      if not core.buildConfig.fast
        if not core.supports 'browserify'
          if (not core.supports 'requirejs') and (not core.supports 'amd')
            grunt.fail.fatal """Sources (client side) cannot be built.
            No rule to build client-side src:
              * browserify [disabled] - static loading
              * requirejs [disabled] - dynamic loading
            Please specify valid support technology to the build sources."""
          else
            taskAmdEntrypointGen = {}
            taskAmdModulesGen = {}
            grunt.log.write "Using Requirejs technology (AMD)"
            i = 0
            for item in fa
              input = fa[i]
              output = faOut[i]
              taskAmdModulesGen[output] =
                files: [{
                  expand: true
                  cwd: amdModCwdDirs[i]
                  dest: amdModDestDirs[i]
                  src: amdModSrcDirs[i]
                }]
              taskAmdEntrypointGen[output] =
                src: "./bin/global_requirejs.js"
                dest: output
                options:
                  footer: "requirejs([\"#{amdModEntrypoints[i]}\"],function(util){});"
              taskAmdEntrypointGen[output+"-common"] =
                src: "./bin/global_requirejs_common.js"
                dest: amdModCommonEntrypoint[i]
                options:
                  footer: ""
              ++i
            core.taskGlob "globtask-build-src", "uglify", taskAmdModulesGen
            core.taskGlob "globtask-build-src", "import", taskAmdEntrypointGen
            #grunt.config.set "uglify", taskAmdModulesGen
            #grunt.task.run "uglify"
            #grunt.config.set "import", taskAmdEntrypointGen
            #grunt.task.run "import"
            i = 0
            for item in fa
              input = fa[i]
              output = faOut[i]
              wiredepAmdCopy =
                files: [{
                  expand: true
                  cwd: "./lib_dist/"
                  src: "./**/*.*"
                  dest: "#{core.buildConfig.dirs.outputClient}/bin/"
                }]
              wiredepAmd =
                src: [ output ]
              if core.supports 'wiredep'
                grunt.log.write "Dependency JS injection was activated (REQUIREJS MODE)"
                #grunt.config.set "bowerRequirejs", wiredepAmd
                #grunt.task.run "bowerRequirejs"
                #TODO: REPAIR
                #core.task amdModEntrypoints[i], "bowerRequirejs", wiredepAmd
                core.taskGlob "globtask-build-src", "bowertaskwire", wiredepAmd
                #core.task amdModEntrypoints[i], "copy", wiredepAmdCopy
              ++i
        else
          taskBrowserify = {}
          if core.buildConfig.standaloneBundling
            grunt.log.write "Using standalone bundling."
            i = 0
            for item in fa
              input = fa[i]
              output = faOut[i]
              taskBrowserify[output] =
                src: input
                dest: output
                options:
                  paths: [
                    "#{core.buildConfig.dirs.assets}/#{amdModEntrypoints[i]}/#{core.buildConfig.dirs.assetsPostfix}"
                  ]
                  plugin: [
                    [ 'errorify' ]
                    [ "browserify-derequire" ]
                    [ "licensify" ]
                  ]
                  transform: [
                    [ "brfs" ]
                    [ "stripify" ]
                    [ "stringify" ]
                    [ "uglifyify" ]
                    [ "debowerify" ]
                  ]
              ++i
            #grunt.config.set "browserify", taskBrowserify
            #grunt.task.run "browserify"
            core.taskGlob "globtask-build-src", "browserify", taskBrowserify
          else
            taskBrowserify = {}
            taskBrowserify["all"] = {
              src: fa
              dest: "#{core.buildConfig.dirs.tmp}/common_prototype__.js"
              options:
                paths: [
                  "#{core.buildConfig.dirs.assets}/#{amdModEntrypoints[i]}/#{core.buildConfig.dirs.assetsPostfix}"
                ]
                plugin: [
                  ['factor-bundle', { o: faOut }]
                  [ 'errorify' ]
                  [ "browserify-derequire" ]
                  [ "licensify" ]
                ]
                transform: [
                  [ "brfs" ]
                  [ "stripify" ]
                  [ "stringify" ]
                  [ "uglifyify" ]
                  [ "debowerify" ]
                ]
            }
            #grunt.config.set "browserify", taskBrowserify
            #grunt.task.run "browserify:all"
            core.taskGlob "globtask-build-src", "browserify", taskBrowserify
            fl = {}
            #grunt.file.delete "#{core.buildConfig.dirs.output}/bin/common.js" if grunt.file.exists "#{core.buildConfig.dirs.output}/bin/common.js"
            grunt.file.write "#{core.buildConfig.dirs.outputClient}/bin/common.js", ""
            grunt.file.write "#{core.buildConfig.dirs.tmp}/common_prototype__.js", ""
            fl["#{core.buildConfig.dirs.outputClient}/bin/common.js"] =
              ["#{core.buildConfig.dirs.tmp}/common_prototype__.js"]
            taskUglify =
              all:
                files: fl
                options: {}
            #grunt.config.set "uglify", taskUglify
            #grunt.task.run "uglify"
            core.taskGlob "globtask-build-src", "uglify", taskUglify
      else
        if not core.watchifyStatus
          core.watchifyStatus = true
          taskWatchify = {}
          i = 0
          fa.forEach (entry) ->
            taskWatchify["unit#{i+1}"] = {
              src: entry
              dest: faOut[i]
              options: {}
            }
            grunt.file.write faOut[i], ''
            ++i
          #grunt.config.set "watchify", taskWatchify
          #grunt.task.run "watchify"
          core.taskGlob "globtask-build-src", "watchify", taskWatchify
