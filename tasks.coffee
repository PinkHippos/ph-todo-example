gulp = require 'gulp'
{exec} = require 'child_process'

######
# All @params will be strings unless specified
######

##### _addBase #####
# Adds the cwd to the path provided.
# Handles for the paths that ignore files
# @returns: string
_addBase = (path)->
  base = "#{__dirname}/"
  if __dirname.split('/').pop() is 'tmp'
    base += '../'
  base += 'ph-todo-'
  if path[0] is '!'
    path = path.slice 1, path.length - 1
    "!#{base}#{path}"
  else
    "#{base}#{path}"

##### _fixPath #####
# Dynamically calls _addBase fn with a src and dest
# @params: src -> string or array
# @returns: object
_fixPath = (service, src, dest)->
  if !dest then dest = 'build'
  fixedPaths = {}
  if Array.isArray src
    # Handling for array type src
    fixedSrc = []
    for path in src
      if service
        fixedSrc.push _addBase "#{service}/#{path}"
      else
        fixedSrc.push _addBase path
  else
    if service
      fixedSrc = _addBase "#{service}/#{src}"
    else
      fixedSrc = _addBase src
  fixedDest = _addBase "#{service}/#{dest}"
  fixedPaths =
    src: fixedSrc
    dest: fixedDest
  fixedPaths

_exec_cmds = (cmds, cb)->
  _err = null
  for cmd in cmds
    console.log 'Executing command', cmd
    exec cmd, (err, stdout, stderr)->
      if err
        _err = err
        console.log "Error with #{cmd}", err
  cb _err

######
# All @returns a .pipe to a gulp.dest unless specified
module.exports =
  ##### clean #####
  # Kills and removes all docker-compose containers
  clean: (cb)->
    clean_cmds = [
      'docker-compose kill'
      'docker-compose rm -f'
    ]
    _exec_cmds clean_cmds, cb

  ##### build #####
  # Pulls and builds all or the given the containers using --no-cache option
  build: (cb, service)->
    build_cmds = [
      'docker-compose pull'
      'docker-compose build --no-cache'
    ]
    if service
      build_cmds = for cmd in build_cmds
        cmd + service
    _exec_cmds build_cmds, cb

  exec_cmds: _exec_cmds

  ##### restart_container #####
  # Restarts the specified service with docker-compose commands
  restart_container: (service, cb)->
    restart_cmds = [
      "docker-compose kill #{service}"
      "docker-compose rm -f #{service}"
      "docker-compose up -d #{service}"
    ]
    _exec_cmds restart_cmds, cb

  ##### watch #####
  # Watches the specified files for changes and runs the
  # @params: cb -> function
  watch: (service, path, cb)->
    {src} = _fixPath service, path
    watch_opts =
      debounceDelay: 1000
      interval: 1000
    gulp.watch src, watch_opts, cb
