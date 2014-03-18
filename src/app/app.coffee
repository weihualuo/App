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

        template = "<side-pane position='left' on-hide='$dismiss()'></side-pane>"
        $scope.sidebar = Popup.modal "modal/sideMenu.tpl.html", locals, template
        $scope.sidebar.promise.then(onItemSelected).finally -> $scope.sidebar = null

    onFilterSelected = (id)->
      console.log id
    filterConfig =
      room:
        title: 'Spcaces'
        any:
          id: 0
          en: 'All spaces'
      style:
        title: 'Style'
        any:
          id: 0
          en: 'Any'
      location:
        title: 'Area'
        any:
          id: 0
          en: 'Any'

    $scope.toggleFilter = (type)->

      if !filterConfig[type]
        console.log "not found", type
        return

      if $scope.filterBar
        $scope.filterBar.end()
        $scope.filterBar = null
      else
        locals =
          title: filterConfig[type].title
          items: [filterConfig[type].any].concat $scope.meta[type]

        template = "<side-pane position='right' on-hide='$dismiss()'></side-pane>"
        $scope.filterBar = Popup.modal "modal/filterBar.tpl.html", locals, template
        $scope.filterBar.promise.then(onFilterSelected).finally -> $scope.filterBar = null

    $scope.onSearch = ->

      if $scope.searchBar
        $scope.searchBar.end()
        $scope.searchBar = null
      else
        locals = {}

        template = "<side-pane position='right' on-hide='$dismiss()'></side-pane>"
        $scope.searchBar = Popup.modal "modal/searchBar.tpl.html", locals, template
        $scope.searchBar.promise.then(onItemSelected).finally -> $scope.searchBar = null

  )


