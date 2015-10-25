matchdep = require 'matchdep'

module.exports = (grunt) ->

  src =
    coffee: [
      'src/**/*.coffee'
    ]
    docs: [
      'src/**/*.coffee'
      'tests/**/*.coffee'
      'docs/README.md'
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

    bump:
      options:
        files: [
          'bower.json'
          'package.json'
        ]
        commitFiles: ['.']
        pushTo: 'origin'

    clean:
      docs: ['docs/*', '!docs/README.md']
      js: { src: ['release/*'], filter: 'isFile' }
      lib: ['lib/*', '!lib/modernizr.js']
      site: ['site/*']
      tests: ['tests/js/*']

      'site-post': [
        'site/release/*{,.map}.js'
        'site/lib/{almond,require}.js'
        '!site/**/*.min.js'
      ]

    copy:
      site:
        expand: yes
        src: [
          'assets/**/*'
          'docs/**/*'
          'lib/**/*'
          'release/**/*'
          'index.html'
        ]
        dest: 'site/'

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

    'gh-pages':
      site:
        options: { base: 'site' }
        src: ['**']

    groc:
      options:
        index: 'docs/README.md'
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
              paths:
                test: '../tests/js'
          vendor: [ 'site/lib/{dat.gui,phaser,underscore}.js' ]

    processhtml:
      site:
        files:
          'site/index.html': 'index.html'

    requirejs:
      compile:
        options:
          # Special Almond configuration.
          baseUrl: './site/release'
          mainConfigFile: 'site/release/game.js'
          include: [ 'game' ]
          insertRequire: [ 'game' ]
          name: '../lib/almond'
          out: 'site/release/game.min.js'
          # Optimization.
          preserveLicenseComments: off

    sass:
      site:
        files: { 'release/site/styles.css': 'src/site/styles.scss' }

    uglify:
      lib:
        files: { 'site/lib/all.min.js': 'site/lib/{dat.gui,phaser,underscore}.js' }

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
  grunt.registerTask 'install', ['bower:lib', 'sass:site', 'autoprefixer:site', 'coffee:src']
  grunt.registerTask 'lib', ['clean:lib', 'bower:lib']
  grunt.registerTask 'publish', [
    'clean:site', 'copy:site', 'requirejs:compile', 'uglify:lib'
    'processhtml:site', 'clean:site-post', 'gh-pages:site'
  ]
  grunt.registerTask 'site', ['sass:site', 'autoprefixer:site', 'watch:site']
  grunt.registerTask 'test', ['clean:tests', 'coffee:tests', 'connect:tests', 'jasmine:tests']

  grunt.registerTask 'default', ['clean:js', 'coffee:src', 'watch:src']
