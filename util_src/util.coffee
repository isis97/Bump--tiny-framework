colors = require 'colors/safe'
node_path = require 'path'
fs = require 'fs'

module.exports =
  fatal: (message) ->
    console.log colors.red("#{message}\n")
    throw new @customError "Fatal Bump! Error"
  customError: (message, extra) ->
    Error.captureStackTrace this, this.constructor
    this.name = this.constructor.name
    this.message = message
    this.extra = extra
  getRelPath: (program) ->
    RelPath = node_path.resolve(program.path)
    RelPath = RelPath.replace(/\\/ig, '/')
    return RelPath
  getBuildConfig: (RelPath) ->
    try
      buildConfig = fs.readFileSync "#{RelPath}/build.json"
      buildConfig = JSON.parse buildConfig
    catch e
      @fatal """Could not find build.json - This is not valid Bump! project.
      Please create valid build.json file in directory: "#{RelPath}"
      Error details:
      #{e.message}
      """
    return buildConfig
  spawnGruntCli: (relpath, task, props) ->
    if not props?
      props = {}
    props.debug = false if not props.debug?
    props.stack = false if not props.stack?
    props.force = false if not props.force?
    props.write = true if not props.write?
    props.color = true if not props.color?
    props.verbose = false if not props.verbose?

    spawnProps =
      gruntfile: __dirname + "/../grunt_entrypoint.coffee"
      debug: props.debug
      stack: props.stack
      force: props.force
      write: props.write
      color: props.color
      verbose: props.verbose
      extra:
        runTask: task
        runConfig: props
        targetPath: relpath
    process.argv = []
    (require 'grunt').cli spawnProps
