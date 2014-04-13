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
      name: 'photos'
      controller: 'PhotoCtrl'
      templateUrl: 'home/photos.tpl.html'
      zIndex: 1
    )
    .when( '/products'
      name: 'products'
      controller: 'ProductCtrl'
      templateUrl: 'home/products.tpl.html'
      zIndex: 1
    )
    .when( '/products/:id'
      name: 'productDetail'
      controller: 'ProductDetailCtrl'
      templateUrl: 'detail/product.tpl.html'
      animation: 'popup-in-right no-sub'
      zIndex: 2
    )
    .when( '/pros'
      name: 'pros'
      controller: 'ProsCtrl'
      templateUrl: 'home/pros.tpl.html'
      zIndex: 1
      )
    .when( '/ideabooks'
      name: 'ideabooks'
      controller: 'IdeabookCtrl'
      templateUrl: 'home/ideabooks.tpl.html'
      zIndex: 1
    )
    .when( '/advice'
      name: 'advice'
      controller: 'AdviceCtrl'
      templateUrl: 'home/advice.tpl.html'
      zIndex: 1
      animation: 'no-sub'
    )
    .when( '/my'
      name: 'my'
      controller: 'MyCtrl'
      templateUrl: 'home/my.tpl.html'
      zIndex: 1
      animation: 'no-sub'
    )
    .otherwise(
      redirectTo: '/photos'
    )
  )
  .value('Env',
    photos:
      filters: ['style', 'room', 'location']
      title: '照片'
    products:
      filters: ['style', 'room']
      title: '产品'
    pros:
      filters: ['location']
      title: '设计师'
    ideabooks:
      filters: ['style', 'room']
      title: '灵感集'
    advice:
      title: '建议'
    my:
      title: '我的家居'
    productDetail:
      title: '产品详情'
  )
  .run( ($location, $document)->
    # simulate html5Mode
    if !location.hash
      $location.path(location.pathname)

    #prevent webkit drag
    $document.on 'touchmove mousemove', (e)->e.preventDefault()
  )
  .controller('AppCtrl', ($scope, Single, Popup, Nav, Service, TogglePane, $timeout, Config, Env, $route) ->

    $scope.onTestDevice = ->
      alert(window.innerWidth+'*'+window.innerHeight+'*'+window.devicePixelRatio)
    
    #Load meta info first
    $scope.meta = Single('meta', Config.$meta).get()
    $scope.meta.$promise.then ->
      $scope.paramUpdateFlag++

    $scope.$watch 'paramUpdateFlag', ->
      if $route.current
        param = $scope.updateFilters $route.current.name
        $scope.cleared = angular.equals(param, {})
        $scope.se = param.se

    #get or update current filter setting
    filterSetting = {}
    $scope.paramUpdateFlag = 0
    $scope.updateFilters = (name, type, value)->
      pathParam = filterSetting[name]
      #init if not exist
      if !angular.isObject(pathParam)
        pathParam = filterSetting[name] = {}
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
      name = $route.current.name
      $scope.pos = name
      $scope.env = Env[name]
      $scope.paramUpdateFlag++

    $scope.onSideMenu = (name)->
      Nav.go name, null, $scope.updateFilters(name)

    $scope.toggleFilter = (type)->

      if !Service.noRepeat('toggleFilter')
        return

      if !Config.$filter[type]
        console.log "not found", type
        return

      name = $route.current.name
      TogglePane
        id: 'filters'
        template: "<side-pane position='right' class='pane-filter-bar popup-in-right'></side-pane>"
        url: "modal/filterBar.tpl.html"
        hash: 'filters'
        locals:
          title: Config.$filter[type].title
          items: [Config.$filter[type].any].concat $scope.meta[type]
          selected: $scope.updateFilters(name)[type] or 0
        success: (id)->
          param = $scope.updateFilters(name, type, id)
          Nav.go name, null, param

    $scope.onAll = ->
      name = $route.current.name
      param = $scope.updateFilters(name, 0)
      Nav.go name, null, param


    $scope.onSearch = (se)->
      name = $route.current.name
      param = $scope.updateFilters(name, 'se', se)
      Nav.go name, null, param
      $timeout -> document.activeElement.blur()


    $scope.getFilterItem = (type)->
      name = $route.current.name
      selected = $scope.updateFilters(name)[type] or 0
      item = _.find $scope.meta[type], id:parseInt(selected)
      if !item
        item = Config.$filter[type].any
      item

  )
  .controller( 'ListCtrl', ($scope, name, $timeout, $routeParams, Many, Popup, Env, MESSAGE) ->

    console.log 'ListCtrl'

    #name = $route.current.name
    $scope.updateFilters(name, $routeParams)
    #uri = path.match(/\/(\w+)/)[1]
    collection = Many(name)
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
        Env[name].rightText = objects.length + $scope.haveMore + '张'
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



