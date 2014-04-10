angular.module( 'app', [ 'ngRoute', 'ngTouch', 'ngAnimate',
                         'templates-app', 'templates-common',
                         'Model', 'app.utils', 'app.home', 'app.detail', 'app.discussion',
                         'myWidget', 'ngCachingView', 'Service', 'ui.popup', 'Scroll'
                         'MESSAGE'
])
  .config( ($routeProvider, $compileProvider) ->
#    // Needed for phonegap routing
    $compileProvider.aHrefSanitizationWhitelist(/^\s*(https?|ftp|mailto|file|tel):/)
    #$locationProvider.html5Mode(true)

    $routeProvider.when( '/photos',
      name: '/photos'
      controller: 'PhotoCtrl'
      templateUrl: 'home/photos.tpl.html'
      zIndex: 1
    )
    .when( '/products'
      name: '/products'
      controller: 'ProductCtrl'
      templateUrl: 'home/products.tpl.html'
      zIndex: 1
    )
    .when( '/products/:id'
      name: '/productView'
      controller: 'ProductDetailCtrl'
      templateUrl: 'detail/product.tpl.html'
      zIndex: 2
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
  .constant('AppConfig',
    meta:
      room:
        title: '空间'
        any:
          id: 0
          en: 'All spaces'
          cn: '所有空间'
      style:
        title: '风格'
        any:
          id: 0
          en: 'Any Style'
          cn: '所有风格'
      location:
        title: '地点'
        any:
          id: 0
          en: 'Any Area'
          cn: '全部地点'
    filters:
      '/photos': ['style', 'room', 'location']
      '/products': ['style', 'room']
      '/pros': ['location']
      '/ideabooks': ['style', 'room']
    titles:
      '/photos': '照片'
      '/products': '产品'
      '/pros': '设计师'
      '/ideabooks': '灵感集'
      '/advice': '建议'
      '/my': '我的家居'

  )
  .run( ($location, $document)->
    # simulate html5Mode
    if !location.hash
      $location.path(location.pathname)

    #prevent webkit drag
    $document.on 'touchmove mousemove', (e)->e.preventDefault()
  )
  .controller('AppCtrl', ($scope, Single, Popup, Nav, Service, TogglePane, $timeout, $location, AppConfig) ->

    console.log 'path',$location.path()

    filterMeta = AppConfig.meta
    pathFilters = AppConfig.filters
    pathTitles = AppConfig.titles
    rightTexts = {}
    
    $scope.onTestDevice = ->
      alert(window.innerWidth+'*'+window.innerHeight+'*'+window.devicePixelRatio)

    #Set the app title to a specific name or default value
    $scope.setTitle = (title)->
      $scope.title = title or $scope.appTitle

    #Set page title
    $scope.setPageTitle = (title)->
      $scope.pageTitle = title or $scope.appTitle

    
    $scope.setRightButton = (title)->
      path = $location.path()
      rightTexts[path] = title
      $scope.rightText = title
    

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

    $scope.$on '$viewContentLoaded', ->
      path = $location.path()
      $scope.pos = path
      $scope.filters = pathFilters[path]
      $scope.rightText = rightTexts[path]
      $scope.title = pathTitles[path]
      $scope.paramUpdateFlag++

    $scope.onSideMenu = (name)->
      Nav.go name, null, $scope.updateFilters(name)


    $scope.toggleSideMenu = ()->
      if !Service.noRepeat('toggleSideMenu')
        return
      menu = document.querySelector('.res-side-pane')
      if menu and menu.offsetHeight
        return

      TogglePane
        id: 'sidebar'
        template: "<side-pane position='left' class='pane-side-menu popup-in-left'></side-pane>"
        url: "modal/sideMenu.tpl.html"
        hash: 'sidemenu'
        locals:
          pos:$location.path()
          onSideMenu: (name)-> @$close(name)
        success: $scope.onSideMenu

    $scope.toggleFilter = (type)->

      if !Service.noRepeat('toggleFilter')
        return

      if !filterMeta[type]
        console.log "not found", type
        return

      path = $location.path()
      TogglePane
        id: 'filters'
        template: "<side-pane position='right' class='pane-filter-bar popup-in-right'></side-pane>"
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

    $scope.onKeyPress = (e, se)->
      if e.keyCode is 13
        $scope.onSearch(se)


    $scope.getFilterItem = (type)->
      path = $location.path()
      selected = $scope.updateFilters(path)[type] or 0
      item = _.find $scope.meta[type], id:parseInt(selected)
      if !item
        item = filterMeta[type].any
      item

  )
  .controller( 'ListCtrl', ($scope, $timeout, $location, $routeParams, Many, Popup, MESSAGE) ->

    console.log 'ListCtrl'

    path = $location.path()
    $scope.updateFilters(path, $routeParams)

    uri = path.match(/\/(\w+)/)[1]

    collection = Many(uri)
    objects = null

    reloadObjects = ->
      # Make sure there is a reflow of empty
      # So that $last in ng-repeat works
      $scope.objects = []
      objects = collection.list($routeParams)
      if !objects.$resolved
        Popup.loading objects.$promise
      objects.$promise.then -> $timeout ->
        $scope.objects = objects
        $scope.haveMore = objects.meta.more
        $scope.setRightButton(objects.length + $scope.haveMore + '张')
        $scope.$broadcast('scroll.reload')

    #Load more objects
    onMore = ->
      if !$scope.haveMore
        $scope.$broadcast('scroll.moreComplete', false)
        console.log "no more"
        return
      promise = collection.more()
      if promise
        $scope.loadingMore = true
        promise.then( (data)->
          $scope.haveMore = objects.meta.more
        ).finally ->
          $scope.loadingMore = false
          $scope.$broadcast('scroll.moreComplete', true)

    #Refresh the list
    onRefresh = ()->
      promise = collection.refresh()
      if promise
        promise.catch(->
          #Popup.alert(MESSAGE.LOAD_FAILED)
        ).finally ->
          $scope.$broadcast('scroll.refreshComplete')

    $scope.$on '$scopeUpdate', reloadObjects
    $scope.$on 'scroll.refreshStart', onRefresh
    $scope.$on 'scroll.moreStart', onMore

  )
  .directive('listFilter', ()->
    restrict: 'E'
    replace: true
    template: '<a class="filter-menu res-display-l" ng-class="{active:item.id}" ng-click="toggleFilter(filter)">{{item.cn || item.en}} <i class="icon ion-arrow-down-b"></i></a>'
    link: (scope, element, attr, ctrl) ->
      #Should use with ng-repeat
      scope.$watch 'paramUpdateFlag', ->
        scope.item = scope.getFilterItem(scope.filter)
  )

