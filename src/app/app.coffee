angular.module( 'app', ['ionic', 'templates-app', 'templates-common',
                        'Model', 'app.home',  'myWidget', 'Service', 'ui.popup',
                        'MESSAGE'
])
  .config( ($stateProvider, $urlRouterProvider, $compileProvider, $locationProvider) ->
#    // Needed for phonegap routing
    $compileProvider.aHrefSanitizationWhitelist(/^\s*(https?|ftp|mailto|file|tel):/)
#    $locationProvider.html5Mode(true)

    $stateProvider.state( 'home',
      url: "/",
      templateUrl: "home/home.tpl.html",
      controller: 'HomeCtrl'
    )
    $urlRouterProvider.otherwise("/")
  )

  .controller('AppCtrl', ($scope, Single) ->

    #Load meta info first
    $scope.meta = Single('meta').get()

  )


