/**
 * This file/module contains all configuration for the build process.
 */
module.exports = {
  /**
   * The `build_dir` folder is where our projects are compiled during
   * development and the `compile_dir` folder is where our app resides once it's
   * completely built.
   */
  build_dir: 'build',
  compile_dir: 'bin',

  /**
   * This is a collection of file patterns that refer to our app code (the
   * stuff in `src/`). These file paths are used in the configuration of
   * build tasks. `js` is all project javascript, less tests. `ctpl` contains
   * our reusable components' (`src/common`) template HTML files, while
   * `atpl` contains the same, but for our app's code. `html` is just our
   * main HTML file, `less` is our main stylesheet, and `unit` contains our
   * app's unit tests.
   */
  app_files: {
    js: [ 'src/**/*.js', '!src/**/*.spec.js' ],
    jsunit: [ 'src/**/*.spec.js' ],
    
    coffee: [ 'src/**/*.coffee', '!src/**/*.spec.coffee' ],
    coffeeunit: [ 'src/**/*.spec.coffee' ],

    atpl: [ 'src/app/**/*.tpl.html' ],
    ctpl: [ 'src/common/**/*.html' ],

    html: [ 'src/index.html' ],
    less: 'src/less/main.less'
  },

  /**
   * This is the same as `app_files`, except it contains patterns that
   * reference vendor code (`vendor/`) that we need to place into the build
   * process somewhere. While the `app_files` property ensures all
   * standardized files are collected for compilation, it is the user's job
   * to ensure non-standardized (i.e. vendor-related) files are handled
   * appropriately in `vendor_files.js`.
   *
   * The `vendor_files.js` property holds files to be automatically
   * concatenated and minified with our project source files.
   *
   * The `vendor_files.css` property holds any CSS files to be automatically
   * included in our app.
   */
  vendor_files: {
      /*!
       * ionic.bundle.js is a concatenation of:
       * ionic.js, angular.js, angular-animate.js,
       * angular-ui-router.js, and ionic-angular.js
       */

    js: [

//        'vendor/ionic-v0.9.26/js/ionic.js',
//        'vendor/ionic-0.9.17-alpha/dist/js/ionic.js',

        'vendor2/ionicCustom/ionic.js',
        'vendor2/ionicCustom/scrollView.js',

        'vendor/angular-1.2.14/angular.js',
        'vendor/angular-1.2.14/angular-animate.js',
        'vendor/angular-1.2.14/angular-touch.js',
        'vendor/angular-1.2.14/angular-sanitize.js',
        'vendor/angular-1.2.14/angular-route.js',

//        'vendor/ionic-v0.9.26/js/ionic-angular.js',
//        'vendor/ionic-0.9.17-alpha/dist/js/ionic-angular.js',

//        'vendor/iscroll/build/iscroll-infinite.js',
//        'vendor/iscroll/build/iscroll-probe.js',
//        'vendor/scroller/src/Animate.js',
//        'vendor/scroller/src/EasyScroller.js',
//        'vendor/scroller/src/Scroller.js',

        'vendor/lodash/lodash.js',
        'vendor/restangular1.2.2/restangular.js',
    ],
    css: [

    ]
  },
};
