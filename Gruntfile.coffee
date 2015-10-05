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

    autoprefixer:
      options:
        browsers: ['last 2 versions', 'ie >= 9']
        cascade: yes
        map: yes
      site:
        files: { 'release/site/styles.css': 'release/site/styles.css' }

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
      js: { src: ['release/*'], filter: 'isFile' }
      lib: ['lib/*']
      tests: ['tests/js/*']

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
            '!tests/js/fakes.js'
          ]
          host: 'http://127.0.0.1:8000/'
          template: require 'grunt-template-jasmine-requirejs'
          templateOptions:
            requireConfigFile: 'release/game.js'
            requireConfig:
              paths: { test: '../tests/js' }

    sass:
      site:
        files: { 'release/site/styles.css': 'src/site/styles.scss' }

    watch:
      src:
        files: src.coffee
        tasks: ['clean:js', 'coffee:src']
      site:
        files: ['src/site/*.scss']
        tasks: ['sass:site']
      docs:
        files: src.docs
        tasks: ['clean:docs', 'groc:docs']

  grunt.loadNpmTasks plugin for plugin in matchdep.filterDev 'grunt-*'

  grunt.registerTask 'docs', ['clean:docs', 'groc:docs', 'watch:docs']
  grunt.registerTask 'lib', ['clean:lib', 'bower:lib']
  grunt.registerTask 'site', ['sass:site', 'autoprefixer:site', 'watch:site']
  grunt.registerTask 'test', ['clean:tests', 'coffee:tests', 'connect:tests', 'jasmine:tests']

  grunt.registerTask 'default', ['clean:js', 'coffee:src', 'watch:src']
