matchdep = require 'matchdep'

module.exports = (grunt) ->

  src =
    coffee: [
      'src/**/*.coffee'
    ]
    docs: [
      'src/**/*.coffee'
      'README.md'
    ]
    tests: [
      'tests/**/*.coffee'
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

    clean:
      docs: ['docs/*']
      js: ['release/*']
      lib: ['lib/*']

    connect:
      tests:
        port: 8000

    coffee:
      options:
        bare: yes
        sourceMap: yes
      src:
        expand: yes
        src: src.coffee
        dest: 'release/'
        ext: '.js'
        flatten: yes
      tests:
        expand: yes
        src: 'tests/**/*.coffee'
        dest: 'tests/js/'
        ext: '.js'
        flatten: yes

    groc:
      options:
        out: 'docs'
        'repository-url': 'https://bitbucket.org/hlfcoding/morning-stroll'
      docs: src.docs

    jasmine:
      tests:
        options:
          specs: [
            'tests/js/*.js'
          ]
          host: 'http://127.0.0.1:8000/'
          template: require 'grunt-template-jasmine-requirejs'
          templateOptions: { requireConfigFile: 'release/app.js' }

    watch:
      js:
        files: src.coffee
        tasks: ['clean:js', 'coffee:src']
      docs:
        files: src.docs
        tasks: ['clean:docs', 'groc:docs']

  grunt.loadNpmTasks plugin for plugin in matchdep.filterDev 'grunt-*'

  grunt.registerTask 'default', ['clean:js', 'coffee:src', 'watch:js']
  grunt.registerTask 'docs', ['clean:docs', 'groc:docs', 'watch:docs']
  grunt.registerTask 'lib', ['clean:lib', 'bower:lib']
  grunt.registerTask 'test', ['coffee:tests', 'connect:tests', 'jasmine:tests']

