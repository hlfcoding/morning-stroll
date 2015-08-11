matchdep = require 'matchdep'

module.exports = (grunt) ->

  src =
    docs: [
      'src/**/*.coffee'
      'README.md'
    ]

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'

    bower:
      lib:
        options:
          cleanBowerDir: yes
          cleanTargetDir: no
          copy: yes
          install: yes
          layout: (type, component) -> ''
          targetDir: 'lib'
          verbose: yes
    groc:
      options:
        out: 'docs'
        'repository-url': 'https://bitbucket.org/hlfcoding/morning-stroll'
      docs: src.docs

    watch:
      docs:
        files: src.docs
        tasks: ['groc']

  grunt.loadNpmTasks plugin for plugin in matchdep.filterDev 'grunt-*'

  grunt.registerTask 'docs', ['groc:docs', 'watch:docs']
  grunt.registerTask 'lib', ['bower:lib']

