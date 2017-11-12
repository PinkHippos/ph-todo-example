gulp = require 'gulp'
{exec} = require 'child_process'
changed = require 'gulp-changed'

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

##### _bundle #####
# Bundles using provided package and handles errs
# @params: bundler -> Browserify or Watchify package
_bundle = (bundler, dest)->
  source = require 'vinyl-source-stream'
  dest = _addBase dest
  bundler
    .bundle()
    .on 'error', (e)->
      console.log "ERROR WITH BUNDLING >>>> #{e.message}"
      console.log e
      @emit 'end'
    .pipe source 'bundle.js'
    .pipe gulp.dest dest

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


##### devStream #####
# Pipes a stream to the gulp-changed package for faster compiles
# @params: stream -> stream from gulp.src
# @returns: stream -> stream
devStream = (stream, dest)->
  changed = require 'gulp-changed'
  plumber = require 'gulp-plumber'
  stream
    .pipe changed dest
    .pipe plumber
      errorHandler: foundError


foundError = (err) ->
  console.log 'PLUGIN ERROR', if err.toJSON then err.toJSON() else err
  @emit 'end'

######
# All @returns a .pipe to a gulp.dest unless specified
module.exports =
  ##### browserify #####
  # Creates initial bundle with browserify
  # Calls bundle with browserify as bundler
  browserify: (service, root, dest)->
    dest = "#{service}/#{dest}" or "#{service}/build/client"
    options =
      entries: "modules/ph-todo-#{service}/build/#{root}"
      debug: true
    browserify = require 'browserify'
    _bundle browserify(options), dest

  ##### coffee #####
  # Compiles coffeescript files to js
  coffee: (service, src, dest)->
    coffee = require 'gulp-coffee'
    sourcemaps = require 'gulp-sourcemaps'
    {src, dest} = _fixPath service, src, dest
    ()->
      gulp.src src
        .pipe changed dest
        .pipe sourcemaps.init()
        .pipe coffee()
          .on 'error', (err)->
            console.log 'Coffee error ---->', err
            @emit 'end'
        .pipe sourcemaps.write()
        .pipe gulp.dest dest

  ##### coffeelint #####
  # Lints the coffeescript files specified
  # Prints the report in the console using 'stylish' reporter
  coffeelint: (src)->
    coffeelint = require 'gulp-coffeelint'
    stylishCoffee = require 'coffeelint-stylish'
    {src} = _fixPath src
    opts =
      max_line_length:
        value: 95
    gulp.src src
      .pipe coffeelint opts
      .pipe coffeelint.reporter 'coffeelint-stylish'


  ##### pug #####
  # Compiles pug into HTML
  pug: (service, src, dest) ->
    pug = require 'gulp-pug'
    {src, dest} = _fixPath service, src, dest
    ()->
      stream = gulp.src src
      if process.env.NODE_ENV is 'development'
        stream = devStream stream, dest
      stream
        .pipe pug()
        .pipe gulp.dest dest


  ##### move #####
  # Moves the files from src to dest
  move: (service, src, dest)->
    {src, dest} = _fixPath service, src, dest
    gulp.src src
      .pipe gulp.dest dest

  copy_src_files: (service, cb)->
    src_path= "ph-todo-#{service}/src"
    machine_path = "xendocker:/home/xenhippo/tmp/#{src_path}"
    cmd = "
    eval $(docker-machine env xendocker) ;\
    docker-machine scp -r #{src_path} #{machine_path}
    "
    console.log "Gulp executing: #{cmd}"
    exec cmd, (err, stdout, stderr)->
      if err
        console.error 'Error with exec', err
        cb err
      else
        console.log stdout
        console.log stderr
        cb()

  #### restart_container ####
  # Restarts the corresponding docker-compose service
  # Uses 'kill' and 'up -d' commands to ensure a good restart
  restart_container: (service, cb)->
    cmds = [
      "docker-compose kill #{service};"
      "docker-compose rm -f #{service};"
      "docker-compose up -d #{service};"
    ]
    _err = null
    for cmd in cmds
      console.log "Gulp executing: #{cmd}"
      exec cmd, (err, stdout, stderr)->
        if err
          console.error 'Error with exec', err
          _err = err
        else
          console.log stdout
          console.log stderr
    cb _err



  ##### stylus #####
  # Compiles Stylus into css
  stylus: (service, src, dest) ->
    styl = require 'gulp-stylus'
    {src, dest} = _fixPath service, src, dest
    ()->
      stream = gulp.src src
      if process.env.NODE_ENV is 'development'
        stream = devStream stream, dest
      stream
        .pipe styl()
        .pipe gulp.dest dest


  ##### watch #####
  # Watches the specified files for changes and runs the
  # @params: cb -> function
  watch: (service, path, cb)->
    {src} = _fixPath service, path
    gulp.watch src, {maxListeners: 999}, cb


  ##### watchify #####
  # Description
  # Creates watcher to update after changes in bundled js files
  # Calls bundle with watchify as bundler
  watchify: (service, root, dest)->
    watchify = require 'watchify'
    browserify = require 'browserify'
    dest = if dest then "#{service}/#{dest}" else "#{service}/build/client"
    options =
      delay: 3000
      entries: "ph-todo-#{service}/build/#{root}"
      debug: true
    watcher = watchify browserify(options), watchify.args
    _bundle watcher, dest
    watcher
      .on 'update', ->
        _bundle watcher, dest
      .on 'log', (log)->
        console.log "Watchify for #{service} log:\n--> #{log}"
