gulp = require 'gulp'
run_sequence = require 'run-sequence'

tasks = require "#{__dirname}/tasks"
{build, clean, restart_container, watch, exec_cmds} = tasks


gulp.task 'default', (cb)->
  run_sequence 'docker', 'watch', cb

gulp.task 'docker', (cb)->
  run_sequence 'docker:clean', 'docker:build', 'docker:start_base', cb
gulp.task 'docker:clean', (cb)->
  clean cb
gulp.task 'docker:build', (cb)->
  build cb
gulp.task 'docker:start_base', (cb)->
  base_services = [
    'rethinkdb'
    'rabbitmq'
  ]
  base_cmds = for service in base_services
    "docker-compose up -d #{service}"
  exec_cmds base_cmds, cb

gulp.task 'watch', (cb)->
  run_sequence [
    'watch:api'
    'watch:auth'
    'watch:db'
    'watch:frontend'
    'watch:worker'
  ], cb

set_tasks = (services)->
  services.forEach (service)->
    console.log 'Creating restart and watch tasks for', service
    gulp.task "restart:#{service}", (cb)->
      restart_container service, cb
    gulp.task "watch:#{service}", (cb)->
      paths = [
        'src/**/*.*'
        'package.json'
      ]
      watch service, paths, ["restart:#{service}", cb]

set_tasks [
  'api'
  'auth'
  'db'
  'frontend'
  'worker'
]
