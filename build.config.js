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
        'vendor/ionic-v0.9.26/js/ionic.bundle.js',
//        'vendor/ionic-0.9.26/js/angular/angular.min.js',
//        'vendor/ionic-0.9.26/js/angular/angular-animate.min.js',
//        'vendor/ionic-0.9.26/js/angular/angular-touch.min.js',
//        'vendor/ionic-0.9.26/js/angular/angular-sanitize.min.js',
//        'vendor/ionic-0.9.26/js/angular/angular-route.min.js',
//        'vendor/ionic-0.9.26/js/angular/angular-resource.min.js',
//        'vendor/ionic-0.9.26/js/ionic-angular.js',

//        'vendor/ionic-0.9.17-alpha/dist/js/ionic.js',
//        'vendor/ionic-0.9.17-alpha/dist/js/angular/angular.min.js',
//        'vendor/ionic-0.9.17-alpha/dist/js/angular/angular-animate.min.js',
//        'vendor/ionic-0.9.17-alpha/dist/js/angular/angular-touch.min.js',
//        'vendor/ionic-0.9.17-alpha/dist/js/angular/angular-sanitize.min.js',
//        'vendor/ionic-0.9.17-alpha/dist/js/angular/angular-route.min.js',
//        'vendor/ionic-0.9.17-alpha/dist/js/angular/angular-resource.min.js',
//        'vendor/ionic-0.9.17-alpha/dist/js/ionic-angular.js',

        'vendor/lodash/lodash.js',
        'vendor/restangular/restangular.min.js',

        'vendor/Gallery/js/blueimp-helper.js',
        'vendor/Gallery/js/blueimp-gallery.js',
        'vendor/Gallery/js/blueimp-gallery-fullscreen.js',
//        'vendor/bootstrap-custom/bootstrap-modal/ui-bootstrap-custom-0.7.0.min.js',
//        'vendor/bootstrap-custom/bootstrap-custom-datepicker/ui-bootstrap-custom-tpls-0.7.0.min.js',
//        'vendor/flat-UI/js/flatui-checkbox.js'
//        'vendor/angular-bootstrap/ui-bootstrap-tpls.min.js',
//        'vendor/placeholders/angular-placeholders-0.0.1-SNAPSHOT.min.js',
//        'vendor/angular-ui-router/release/angular-ui-router.js',
//        'vendor/angular-ui-utils/modules/route/route.js',
//		'vendor/iscroll-4/src/iscroll.js'
    ],
    css: [

    ]
  },
};
