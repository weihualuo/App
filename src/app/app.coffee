angular.module( 'app', ['ionic', 'ngRoute', 'ngTouch',
                        'templates-app', 'templates-common',
                        'Model', 'app.home', 'app.discussion',
                        'myWidget', 'ngCachingView', 'Service', 'ui.popup',
                        'MESSAGE'
])
  .config( ($routeProvider, $compileProvider, $locationProvider) ->
#    // Needed for phonegap routing
    $compileProvider.aHrefSanitizationWhitelist(/^\s*(https?|ftp|mailto|file|tel):/)
#    $locationProvider.html5Mode(true)

    $routeProvider.when( '/photos',
      name: '/photos'
      controller: 'ListCtrl'
      templateUrl: 'home/photos.tpl.html'
      zIndex: 1
    )
    .when( '/products'
      name: '/products'
      controller: 'ListCtrl'
      templateUrl: 'home/products.tpl.html'
      zIndex: 1
    )
    .when( '/pros'
      name: '/pros'
      controller: 'ListCtrl'
      templateUrl: 'home/pros.tpl.html'
      zIndex: 1
    )
    .when( '/ideabooks'
      name: '/ideabooks'
      controller: 'ListCtrl'
      templateUrl: 'home/ideabooks.tpl.html'
      zIndex: 1
    )
    .when( '/advice'
      name: '/advice'
      controller: 'AdviceCtrl'
      templateUrl: 'home/advice.tpl.html'
      zIndex: 1
    )
    .when( '/my'
      name: '/my'
      controller: 'MyCtrl'
      templateUrl: 'home/my.tpl.html'
      zIndex: 1
    )
    .otherwise(
      redirectTo: '/photos'
    )
  )

  .controller('AppCtrl', ($scope, Single, Popup, Nav, $timeout, $location) ->

    #Load meta info first
    $scope.meta = Single('meta').get()

    #Set the app title to a specific name or default value
    $scope.setTitle = (title)->
      $scope.title = title or $scope.appTitle

    #Set page title
    $scope.setPageTitle = (title)->
      $scope.pageTitle = title or $scope.appTitle


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

    filterParam = {}
    updateFilters = (path, type, value)->
      pathParam = filterParam[path]
      #init if not exist
      if !angular.isObject(pathParam)
        pathParam = filterParam[path] = {}
      #update
      if angular.isString(type)
        if value
          pathParam[type] = value
        else
          delete pathParam[type]
      #return
      pathParam

    sidebar = null
    $scope.toggleSideMenu = ()->
      if sidebar
        sidebar.end()
        sidebar = null
      else
        pos = $location.path()
        locals = pos:pos
        template = "<side-pane position='left' on-hide='$close()'></side-pane>"
        sidebar = Popup.modal "modal/sideMenu.tpl.html", locals, template, 'sidemenu'
        sidebar.promise.then( (name)->
          Nav.go name, null, updateFilters(name)
        ).finally -> sidebar = null



    filterBar = null
    $scope.toggleFilter = (type)->

      if !filterConfig[type]
        console.log "not found", type
        return

      if filterBar
        filterBar.end()
        filterBar = null
      else
        path = $location.path()
        locals =
          title: filterConfig[type].title
          items: [filterConfig[type].any].concat $scope.meta[type]
          selected: updateFilters(path)[type] or 0

        template = "<side-pane position='right' on-hide='$close()'></side-pane>"
        filterBar = Popup.modal "modal/filterBar.tpl.html", locals, template
        filterBar.promise.then((id)->
          param = updateFilters(path, type, id)
          console.log 'id=',id
          Nav.go path, null, param
        ).finally -> filterBar = null

    $scope.onSearch = ->

      if $scope.searchBar
        $scope.searchBar.end()
        $scope.searchBar = null
      else
        locals = {}

        template = "<side-pane position='right' on-hide='$close()'></side-pane>"
        $scope.searchBar = Popup.modal "modal/searchBar.tpl.html", locals, template, 'search'
        $scope.searchBar.promise.then().finally -> $scope.searchBar = null

  )
  .controller( 'ListCtrl', ($scope, $timeout, $filter, $location, $routeParams, Many, Popup, MESSAGE) ->

    console.log 'ListCtrl'

    uri = $location.path().match(/\/(\w+)/)[1]

    collection = Many(uri)
    objects = null

    scrollResize = (reset)->
      $scope.scrollView.scrollTo(0,0) if $scope.scrollView and reset
      #Wait for the list render progress completed
      $timeout (->$scope.$broadcast('scroll.resize')), 300

    reloadObjects = ->
      $scope.objects = objects = collection.list($routeParams)
      if !objects.$resolved
        Popup.loading objects.$promise, null, MESSAGE.LOAD_FAILED

      objects.$promise.then ->
        $scope.haveMore = objects.meta.more
        $scope.total = objects.length + $scope.haveMore
        scrollResize(true)

    $scope.$on '$scopeUpdate', reloadObjects

    #Load more objects
    $scope.onMore = ->
      if !$scope.haveMore or !collection
        return
      promise = collection.more()
      if promise
        promise.then (data)->
          $scope.haveMore = objects.meta.more

    #Refresh the list
    $scope.onRefresh = ()->
      promise = collection.refresh()
      if promise
        promise.catch(->
          $popup.alert(MESSAGE.LOAD_FAILED)
        ).finally ->
          $scope.$broadcast('scroll.refreshComplete')
          scrollResize()

  )


