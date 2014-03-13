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

  .controller('AppCtrl', ($scope, Single, Popup) ->

    #Load meta info first
    $scope.meta = Single('meta').get()

    $scope.sideItems = [
                        {icon: 'ion-ios7-photos', content: 'Photos'}
                        {icon: 'ion-ios7-cart', content: 'Products'}
                        {icon: 'ion-social-designernews', content: 'Professionals'}
                        {icon: 'ion-ios7-bookmarks', content: 'Ideabooks'}
                        {icon: 'ion-chatboxes', content: 'Discussions'}
                        {icon: 'ion-person', content: 'My Houzz'}
                        ]


    $scope.toggleSideMenu = ->

      if $scope.sidebar
        $scope.sidebar.end()
        $scope.sidebar = null
      else
        locals =
          items: $scope.sideItems
        template = "<side-menu on-hide='$dismiss()'></side-menu>"
        $scope.sidebar = Popup.modal "modal/sideMenu.tpl.html", locals, template
        $scope.sidebar.promise.then( (item)->
          console.log item
        ).finally ->
          $scope.sidebar = null

  )


