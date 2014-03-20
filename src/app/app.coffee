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
      resolve:
        listFilters: -> ['style', 'room', 'location']
    )
    .when( '/products'
      name: '/products'
      controller: 'ListCtrl'
      templateUrl: 'home/products.tpl.html'
      zIndex: 1
      resolve:
        listFilters: -> ['style', 'room']
    )
    .when( '/pros'
      name: '/pros'
      controller: 'ListCtrl'
      templateUrl: 'home/pros.tpl.html'
      zIndex: 1
      resolve:
        listFilters: -> ['location']
      )
    .when( '/ideabooks'
      name: '/ideabooks'
      controller: 'ListCtrl'
      templateUrl: 'home/ideabooks.tpl.html'
      zIndex: 1
      resolve:
        listFilters: -> ['style', 'room', ]
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
          en: 'Any Style'
      location:
        title: 'Area'
        any:
          id: 0
          en: 'Any Area'

    #Load meta info first
    $scope.meta = Single('meta').get()
    $scope.meta.$promise.then ->
      $scope.paramUpdateFlag++

    $scope.filterParam = {}
    $scope.paramUpdateFlag = 0
    $scope.updateFilters = (path, type, value)->
      pathParam = $scope.filterParam[path]
      #init if not exist
      if !angular.isObject(pathParam)
        pathParam = $scope.filterParam[path] = {}
      #update
      if angular.isString(type)
        $scope.paramUpdateFlag++
        if value
          pathParam[type] = value
        else
          delete pathParam[type]

      else if angular.isObject(type)
        angular.copy(type, pathParam)
        $scope.paramUpdateFlag++

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
          Nav.go name, null, $scope.updateFilters(name)
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
          selected: $scope.updateFilters(path)[type] or 0

        template = "<side-pane position='right' on-hide='$close()'></side-pane>"
        filterBar = Popup.modal "modal/filterBar.tpl.html", locals, template
        filterBar.promise.then((id)->
          param = $scope.updateFilters(path, type, id)
          Nav.go path, null, param
        ).finally -> filterBar = null

    $scope.getFilterTitle = (type)->
      path = $location.path()
      selected = $scope.updateFilters(path)[type] or 0
      item = _.find $scope.meta[type], id:parseInt(selected)
      if !item
        item = filterConfig[type].any
      item.en

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
  .controller( 'ListCtrl', ($scope, $timeout, $filter, $location, $routeParams, Many, Popup, MESSAGE, listFilters) ->

    console.log 'ListCtrl'

    $scope.filters =  listFilters

    path = $location.path()
    $timeout -> $scope.updateFilters(path, $routeParams)

    uri = path.match(/\/(\w+)/)[1]

    collection = Many(uri)
    objects = null

    scrollResize = (reset)->
      $scope.scrollView.scrollTo(0,0) if $scope.scrollView and reset
      #Wait for the list render progress completed
      $timeout (->$scope.$broadcast('scroll.resize')), 1000

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
  .directive('listFilter', ()->
    restrict: 'E'
    replace: true
    scope: true
    template: '<a class="pull-right padding" ng-click="toggleFilter(id)">{{value}} <i class="icon ion-arrow-down-b"></i></a>'
    link: (scope, element, attr, ctrl) ->
      scope.id = attr.id
      scope.$watch 'paramUpdateFlag', (value)->
        scope.value = scope.getFilterTitle(scope.id)
  )

