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

    coffee:
      options:
        sourceMap: yes
      src:
        expand: yes
        src: src.coffee
        dest: 'release/'
        ext: '.js'
        extDot: 'last'
        flatten: yes

    groc:
      options:
        out: 'docs'
        'repository-url': 'https://bitbucket.org/hlfcoding/morning-stroll'
      docs: src.docs

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

