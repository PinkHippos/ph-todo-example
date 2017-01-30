gulp = require 'gulp'
runSequence = require 'run-sequence'
tasks = require "#{__dirname}/tasks"
{browserify, coffee, pug} = tasks
{stylus, watchify, watch} = tasks

######
# Place to store paths that will be used again
# '../modules/ph-todo-<serviceName>' is appended
paths =
  client_root: 'build/client/js/app.js'
  pug:
    compile: 'src/**/*.pug'
    all: ['src/**/*.pug']
  server: 'build/server-assets/server.js'
  stylus:
    compile: 'src/**/**/*.styl'
    all: ['src/**/**/*.styl']
  coffee:
    compile: 'src/**/*.coffee'
    all: ['src/**/*.coffee']


gulp.task 'default', (cb)->
  runSequence 'build', 'watch', cb

gulp.task 'build', [
  'api:build'
  'auth:build'
  'db:build'
  'frontend:build'
  'worker:build'
]

gulp.task 'watch', (cb)->
  runSequence [
    'api:watch'
    'auth:watch'
    'db:watch'
    'frontend:watch'
    'worker:watch'
    'frontend:watchify'
  ], cb

gulp.task 'api:build', (cb)->
  gulp.task 'coffee:api', coffee 'api', paths.coffee.compile, 'build'
  runSequence 'coffee:api', cb
gulp.task 'api:watch', (cb)->
  watch 'api', paths.coffee.compile, ['coffee:api', cb]

gulp.task 'auth:build', (cb)->
  gulp.task 'coffee:auth', coffee 'auth', paths.coffee.compile, 'build'
  runSequence 'coffee:auth', cb
gulp.task 'auth:watch', (cb)->
  watch 'auth', paths.coffee.compile, ['coffee:auth', cb]

gulp.task 'db:build', (cb)->
  gulp.task 'coffee:db', coffee 'db', paths.coffee.compile, 'build'
  runSequence 'coffee:db', cb
gulp.task 'db:watch', (cb)->
  watch 'db', paths.coffee.compile, ['coffee:db', cb]

gulp.task 'frontend:build', (cb)->
  gulp.task 'coffee:frontend', coffee 'frontend', paths.coffee.compile, 'build'
  gulp.task 'pug:frontend', pug 'frontend', paths.pug.compile, 'build'
  gulp.task 'stylus:frontend', stylus 'frontend', paths.stylus.compile, 'build'
  runSequence ['coffee:frontend', 'pug:frontend', 'stylus:frontend'], cb
gulp.task 'frontend:watch', (cb)->
  watch 'frontend', paths.coffee.compile, ['coffee:frontend', cb]
  watch 'frontend', paths.pug.compile, ['pug:frontend', cb]
  watch 'frontend', paths.stylus.compile, ['stylus:frontend', cb]
gulp.task 'watchify', watchify paths.client_root

gulp.task 'worker:build', (cb)->
  gulp.task 'coffee:worker', coffee 'worker', paths.coffee.compile, 'build'
  runSequence 'coffee:worker', cb
gulp.task 'worker:watch', (cb)->
  watch 'worker', paths.coffee.compile, ['coffee:worker', cb]
