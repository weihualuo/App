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
  .constant('FilterConfig',
    meta:
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
    filters:
      '/photos': ['style', 'room', 'location']
      '/products': ['style', 'room']
      '/pros': ['location']
      '/ideabooks': ['style', 'room']
    
  )
  .controller('AppCtrl', ($scope, Single, Popup, Nav, Service, $timeout, $location, FilterConfig) ->

    $scope.onTestDevice = ->
      alert(window.innerWidth+'*'+window.innerHeight+'*'+window.devicePixelRatio)

    #Set the app title to a specific name or default value
    $scope.setTitle = (title)->
      $scope.title = title or $scope.appTitle

    #Set page title
    $scope.setPageTitle = (title)->
      $scope.pageTitle = title or $scope.appTitle

    filterMeta = FilterConfig.meta

    $scope.setFilters = (filters)->
      $scope.filters =  filters
      $scope.paramUpdateFlag++

    #Load meta info first
    $scope.meta = Single('meta').get()
    $scope.meta.$promise.then ->
      $scope.paramUpdateFlag++

    $scope.$watch 'paramUpdateFlag', ->
      param = $scope.updateFilters $location.path()
      $scope.cleared = angular.equals(param, {})
      $scope.se = param.se

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
          pathParam[type] = String value
        else
          delete pathParam[type]

      else if angular.isObject(type)
        angular.copy(type, pathParam)
        $scope.paramUpdateFlag++

      else if type is 0
        angular.copy({}, pathParam)
        $scope.paramUpdateFlag++

      #return
      pathParam

    panes = {}
    $scope.togglePane = (param)->
      {id, locals, template, url, hash, success, fail, always} = param
      if panes[id]
        panes[id].end()
        panes[id] = null
      else if id
        panes[id] = Popup.modal url, locals, template, hash
        panes[id].promise.then(success, fail).finally ->
          panes[id] = null
          if always then always()

    $scope.$on '$viewContentLoaded', ->
      path = $location.path()
      $scope.pos = path
      $scope.filters = FilterConfig.filters[path]

    $scope.onSideMenu = (name)->
      Nav.go name, null, $scope.updateFilters(name)


    $scope.toggleSideMenu = ()->
      if !Service.noRepeat('toggleSideMenu',2000)
        return

      $scope.togglePane
        id: 'sidebar'
        template: "<side-pane position='left' on-hide='$close()'></side-pane>"
        url: "modal/sideMenu.tpl.html"
        hash: 'sidemenu'
        locals:
          pos:$location.path()
          onSideMenu: (name)-> @$close(name)
        success: $scope.onSideMenu

    $scope.toggleFilter = (type)->

      if !Service.noRepeat('toggleFilter',2000)
        return

      if !filterMeta[type]
        console.log "not found", type
        return

      path = $location.path()
      $scope.togglePane
        id: 'filters'
        template: "<side-pane position='right' on-hide='$close()'></side-pane>"
        url: "modal/filterBar.tpl.html"
        hash: 'filters'
        locals:
          title: filterMeta[type].title
          items: [filterMeta[type].any].concat $scope.meta[type]
          selected: $scope.updateFilters(path)[type] or 0
        success: (id)->
          param = $scope.updateFilters(path, type, id)
          Nav.go path, null, param

    $scope.onAll = ->
      path = $location.path()
      param = $scope.updateFilters(path, 0)
      Nav.go path, null, param


    $scope.onSearch = (se)->
      path = $location.path()
      param = $scope.updateFilters(path, 'se', se)
      Nav.go path, null, param
      $timeout -> document.activeElement.blur()


    $scope.getFilterTitle = (type)->
      path = $location.path()
      selected = $scope.updateFilters(path)[type] or 0
      item = _.find $scope.meta[type], id:parseInt(selected)
      if !item
        item = filterMeta[type].any
      item.en

  )
  .controller( 'ListCtrl', ($scope, $timeout, $filter, $location, $routeParams, Many, Popup, MESSAGE) ->

    console.log 'ListCtrl'

    path = $location.path()
    $scope.updateFilters(path, $routeParams)

    uri = path.match(/\/(\w+)/)[1]

    collection = Many(uri)
    objects = null

    scrollResize = (reset)->
      $scope.scrollView.scrollTo(0,0) if $scope.scrollView and reset
      #Wait for the list render progress completed
      $timeout (->$scope.$broadcast('scroll.resize')), 1000

    resetState = -> no

    reloadObjects = ->

      $scope.objects = objects = collection.list($routeParams)
      if !objects.$resolved
        Popup.loading objects.$promise, null, MESSAGE.LOAD_FAILED

      objects.$promise.then ->
        $scope.haveMore = objects.meta.more
        $scope.total = objects.length + $scope.haveMore
        scrollResize(true)

    $scope.$on '$scopeUpdate', reloadObjects
    $scope.$on '$viewContentLoaded', resetState

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
      scope.$watch 'paramUpdateFlag', ->
        scope.value = scope.getFilterTitle(scope.id)
  )

