matchdep = require 'matchdep'

module.exports = (grunt) ->

  SOURCES =
    DOCS:
      PRIVATE: [
        'src/**/*.coffee'
        'README.md'
      ]

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    bower:
      install:
        options:
          cleanBowerDir: yes
          cleanTargetDir: no
          copy: yes
          install: yes
          layout: (type, component) -> ''
          targetDir: 'lib'
          verbose: yes
    groc:
      private: SOURCES.DOCS.PRIVATE
      options:
        out: 'docs'
        'repository-url': 'https://bitbucket.org/hlfcoding/morning-stroll'
    watch:
      docs:
        files: SOURCES.DOCS.PRIVATE
        tasks: ['groc:private']
        options:
          spawn: no

  grunt.loadNpmTasks plugin for plugin in matchdep.filterDev 'grunt-*'

  grunt.registerTask 'default', ['bower:install']
  grunt.registerTask 'docs', ['groc', 'watch:docs']

