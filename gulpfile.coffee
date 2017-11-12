gulp = require 'gulp'
runSequence = require 'run-sequence'
{exec} = require 'child_process'
tasks = require "#{__dirname}/tasks"
{browserify, coffee, pug, move} = tasks
{restart_container, stylus, watchify, watch, copy_src_files} = tasks

######
# Place to store paths that will be used again
# '../modules/ph-todo-<serviceName>' is appended
paths =
  vendor: [
    'node_modules/bootstrap/dist/css/bootstrap.min.css'
    'node_modules/bootstrap/dist/js/bootstrap.min.js'
    'node_modules/jquery/dist/jquery.min.js'
  ]
  client_root: 'client/js/app.js'
  pug: 'src/**/*.pug'
  server: 'build/server-assets/server.js'
  stylus:'src/**/**/*.styl'
  coffee:'src/**/*.coffee'


gulp.task 'default', (cb)->
  runSequence 'build', 'watch', cb


gulp.task 'build', [
  'api:build'
  # 'auth:build'
  'db:build'
  # 'frontend:build'
  'worker:build'
]

gulp.task 'watch', (cb)->
  # exec 'eval $(docker-machine env xendocker)'
  runSequence [
    'api:watch'
    # 'auth:watch'
    'db:watch'
    # 'frontend:watch'
    'worker:watch'
    # 'frontend:watchify'
  ], cb

gulp.task 'docker_watch', (cb)->
  runSequence [
    'api:docker_watch'
    'auth:docker_watch'
    'db:docker_watch'
    'frontend:docker_watch'
    'worker:docker_watch'
  ]


gulp.task 'api:build', (cb)->
  gulp.task 'coffee:api', coffee 'api', paths.coffee, 'build'
  runSequence 'coffee:api', cb
gulp.task 'restart:api', (cb)->
  restart_container 'api', cb
gulp.task 'api:watch', (cb)->
  watch 'api', paths.coffee, ['coffee:api', cb]
gulp.task 'api:docker_watch', (cb)->
  watch 'api', paths.coffee, ['restart:api', cb]

gulp.task 'auth:build', (cb)->
  gulp.task 'coffee:auth', coffee 'auth', paths.coffee, 'build'
  runSequence 'coffee:auth', cb
gulp.task 'restart:auth', (cb)->
  restart_container 'auth', cb
gulp.task 'auth:watch', (cb)->
  watch 'auth', paths.coffee, ['restart:auth', cb]
gulp.task 'auth:docker_watch', (cb)->
  watch 'auth', paths.coffee, ['restart:auth', cb]

gulp.task 'db:build', (cb)->
  gulp.task 'coffee:db', coffee 'db', paths.coffee, 'build'
  runSequence 'coffee:db', cb
gulp.task 'restart:db', (cb)->
  restart_container 'db', cb
gulp.task 'db:watch', (cb)->
  watch 'db', paths.coffee, ['coffee:db', cb]
gulp.task 'db:docker_watch', (cb)->
  watch 'db', paths.coffee, ['restart:db', cb]

gulp.task 'frontend:build', (cb)->
  gulp.task 'coffee:frontend', coffee 'frontend', paths.coffee, 'build'
  gulp.task 'pug:frontend', pug 'frontend', paths.pug, 'build'
  gulp.task 'stylus:frontend', stylus 'frontend', paths.stylus, 'build'
  gulp.task 'vendor:frontend', ->
    move 'frontend', paths.vendor, 'build/client/vendor'
  runSequence [
    'coffee:frontend'
    'pug:frontend'
    'stylus:frontend'
    'vendor:frontend'
    ], cb
gulp.task 'frontend:watch', (cb)->
  watch 'frontend', paths.coffee, ['coffee:frontend', cb]
  watch 'frontend', paths.pug, ['pug:frontend', cb]
  watch 'frontend', paths.stylus, ['stylus:frontend', cb]
gulp.task 'frontend:watchify', ->
  watchify 'frontend', paths.client_root
gulp.task 'restart:frontend', (cb)->
  restart_container 'frontend', cb
gulp.task 'frontend:docker_watch', (cb)->
  watch 'frontend', 'src/**/*.*', ['restart:frontend', cb]

gulp.task 'worker:build', (cb)->
  gulp.task 'coffee:worker', coffee 'worker', paths.coffee, 'build'
  runSequence 'coffee:worker', cb
gulp.task 'restart:worker', (cb)->
  restart_container 'worker', cb
gulp.task 'worker:watch', (cb)->
  watch 'worker', paths.coffee, ['coffee:worker', cb]
gulp.task 'worker:docker_watch', (cb)->
  watch 'worker', paths.coffee, ['restart:worker', cb]
