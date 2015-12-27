process = require 'child_process'

module.exports = (grunt, core) ->
  grunt.registerTask "run-server", "Runs local server", () ->
    if core.serverProcess
      core.serverProcess.kill()
      core.serverProcess = null
      grunt.log.write "Server stopped."
    if core.supports 'node'
      if not grunt.file.exists "#{core.buildConfig.dirs.outputServer}/node/main.js"
        grunt.fail.fatal "The node server cannot be started. The node.js entry point does not exist (#{core.buildConfig.dirs.outputServer}/node/main.js)."
      core.serverProcess = process.fork "#{core.buildConfig.dirs.outputServer}/node/main.js"
      grunt.log.write "Server started."
    else
      grunt.task.run "connect:server"
