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

  .controller('AppCtrl', ($scope, Single, Popup, $timeout) ->

    #Load meta info first
    $scope.meta = Single('meta').get()

    $scope.sideItems = [
                        {icon: 'ion-ios7-photos', content: 'Photos', value: 'photos'}
                        {icon: 'ion-ios7-cart', content: 'Products', value: 'products'}
                        {icon: 'ion-social-designernews', content: 'Professionals', value: 'pros'}
                        {icon: 'ion-ios7-bookmarks', content: 'Ideabooks', value: 'ideabooks'}
                        {icon: 'ion-chatboxes', content: 'Discussions', value: 'discussions'}
                        {icon: 'ion-person', content: 'My Houzz', value: 'my'}
                        ]


    $scope.selected = $scope.sideItems[0]

    $scope.toggleSideMenu = ->

      if $scope.sidebar
        $scope.sidebar.end()
        $scope.sidebar = null
      else
        locals =
          items: $scope.sideItems
          selected: $scope.selected

        template = "<side-menu on-hide='$dismiss()'></side-menu>"
        $scope.sidebar = Popup.modal "modal/sideMenu.tpl.html", locals, template
        $scope.sidebar.promise.then( (item)->
          $scope.selected = item
          $scope.$broadcast('item.changed', item.value)
        ).finally ->
          $scope.sidebar = null

    $timeout -> $scope.$broadcast('item.changed', $scope.selected.value)
  )


