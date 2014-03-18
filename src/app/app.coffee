angular.module( 'app', ['ionic', 'ngRoute', 'ngTouch', 'templates-app', 'templates-common',
                        'Model', 'app.home', 'app.discussion', 'myWidget', 'CachingView', 'Service', 'ui.popup',
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
    .state( 'discussion',
      url: "/dis",
        templateUrl: "discussion/discussion.tpl.html",
        controller: 'DiscussionCtrl'
    )


    $urlRouterProvider.otherwise("/")
  )

  .controller('AppCtrl', ($scope, Single, Popup, $timeout, $state) ->

    console.log $state

    #Load meta info first
    $scope.meta = Single('meta').get()

    $scope.sideItems = [
                        {icon: 'ion-ios7-photos', content: 'Photos', value: 'photos', view: 'home'}
                        {icon: 'ion-ios7-cart', content: 'Products', value: 'products', view: 'home'}
                        {icon: 'ion-social-designernews', content: 'Professionals', value: 'pros', view: 'home'}
                        {icon: 'ion-ios7-bookmarks', content: 'Ideabooks', value: 'ideabooks', view: 'home'}
                        {icon: 'ion-chatboxes', content: 'Discussions', value: 'discussions', view: 'discussion'}
                        {icon: 'ion-person', content: 'My Houzz', value: 'my', view: 'my'}
                        ]



    onItemSelected = (item)->
      $scope.selected = item
      console.log 'view', item.view, $state.current.name
      $scope.$broadcast('item.changed', item)
#      if item.view != $state.current.name
#        $state.go item.view
#      #defaut route to home viewe
#      else
#        $scope.$broadcast('item.changed', item)

    $timeout -> onItemSelected($scope.sideItems[0])

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
        $scope.sidebar.promise.then(onItemSelected).finally -> $scope.sidebar = null

  )


