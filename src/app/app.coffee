angular.module( 'app', [ 'ngRoute', 'ngTouch', 'ngAnimate', 'ngSanitize',
                         'templates-app', 'templates-common', 'Model', 'MESSAGE'
                         'app.utils', 'app.home', 'app.photo', 'app.product',
                         'app.ideabook', 'app.my', 'app.pro', 'app.advice',
                         'CacheView', 'Service', 'Popup', 'Scroll', 'Widget'
])
  .config( ($routeProvider, $compileProvider, $httpProvider) ->
#    // Needed for phonegap routing
    $compileProvider.aHrefSanitizationWhitelist(/^\s*(https?|ftp|mailto|file|tel):/)
    #$locationProvider.html5Mode(true)
    $httpProvider.defaults.xsrfHeaderName = 'X-CSRFToken'
    $httpProvider.defaults.xsrfCookieName = 'csrftoken'

    if window.SERVER
      $httpProvider.defaults.withCredentials = true
      $httpProvider.defaults.headers.common['X-CSRFToken'] = localStorage.csrf

    $routeProvider.when( '/photos',
      name: 'photos'
      controller: 'PhotoCtrl'
      templateUrl: 'photo/photos.tpl.html'
      cache: yes
    )
    .when( '/photoDetail',
      name: 'photoDetail'
      controller: 'PhotoDetailCtrl'
      templateUrl: 'photo/photoDetail.tpl.html'
      class: 'no-background no-header no-side'
            
    )
    .when( '/photos/:id/info'
      name: 'photoInfo'
      controller: 'PhotoInfoCtrl'
      templateUrl: 'photo/photoInfo.tpl.html'
      class: 'popup-mode'
    )
    .when( '/products'
      name: 'products'
      controller: 'ProductCtrl'
      templateUrl: 'product/products.tpl.html'
      cache: yes

    )
    .when( '/products/:id'
      name: 'productDetail'
      controller: 'ProductDetailCtrl'
      templateUrl: 'product/product.tpl.html'
      class: 'no-sub no-side'
      extends:
        $aniIn: 'from-right'
        $aniOut: 'from-right'
    )
    .when( '/pros'
      name: 'pros'
      controller: 'ProsCtrl'
      templateUrl: 'pro/pros.tpl.html'
      cache: yes
    )
    .when( '/pros/:id'
      name: 'userDetail'
      controller: 'UserDetailCtrl'
      templateUrl: 'pro/userInfo.tpl.html'
      class: 'popup-mode'
    )
    .when( '/ideabooks'
      name: 'ideabooks'
      controller: 'IdeabookCtrl'
      templateUrl: 'ideabook/ideabooks.tpl.html'
      cache: yes
    )
    .when( '/ideabooks/:id'
      name: 'ideabookDetail'
      controller: 'IdeabookDetailCtrl'
      templateUrl: 'ideabook/ideabook.tpl.html'
      class: 'no-sub no-side'
      extends:
        $aniIn: 'from-right'
        $aniOut: 'from-right'
    )
    .when( '/ideabooks/:id/unit'
      name: 'ideabookUnit'
      controller: 'PhotoDetailCtrl'
      templateUrl: 'photo/photoDetail.tpl.html'
      class: 'no-background no-header no-side'
    )
    .when( '/advices'
      name: 'advices'
      controller: 'AdviceCtrl'
      templateUrl: 'advice/advices.tpl.html'
      cache: yes
    )
    .when( '/advice/:id'
      name: 'adviceDetail'
      controller: 'AdviceDetailCtrl'
      templateUrl: 'advice/advice.tpl.html'
      class: 'no-sub no-side'
      extends:
        $aniIn: 'from-right'
        $aniOut: 'from-right'
    )
    .when( '/my'
      name: 'my'
      controller: 'MyCtrl'
      templateUrl: 'my/my.tpl.html'
      class: 'no-sub has-form'
      cache: yes
    )
    .when( '/:parent/:pid/comments'
      name: 'comments'
      controller: 'CommentCtrl'
      templateUrl: 'advice/comment.tpl.html'
      class: 'popup-mode'
    )
    .otherwise(
      redirectTo: '/photos'
    )
  )
  .value('Env',
    photos:
      filters: ['style', 'room', 'location']
      title: '照片'
      right: ['<i class="icon ion-ios7-upload-outline"></i>']
    products:
      filters: ['style', 'room']
      title: '产品'
      right: []
    pros:
      filters: ['location']
      title: '设计师'
    userDetail:
      title: '详细资料'
      popup: yes
    ideabooks:
      filters: []
      title: '灵感集'
    advices:
      filters: ['topic']
      title: '建议'
      right: ['新建讨论']
    adviceDetail:
      noSide: true
      title: '建议'
      right: ['评论']
    comments:
      popup: yes
    my:
      title: '我的家居'
      right: []
    productDetail:
      title: '产品详情'
      noSide: true
    photoDetail:
      title: '照片详情'
      noSide: true
      noHeader: true
    ideabookDetail:
      noSide: true
      title: '灵感集'
      right: ['评论']
    ideabookUnit:
      noSide: true
      noHeader: true
    photoInfo:
      popup: yes
  )
  .run( ($location, $document, $rootScope)->
    # simulate html5Mode
    if !location.hash
      $location.path(location.pathname)

    #prevent webkit drag
    $document.on 'touchmove mousemove', (e)->e.preventDefault()
    window.addEventListener 'resize', ->
      $rootScope.$broadcast('resize')
  )
  .directive('listFilter', ()->
    restrict: 'E'
    replace: true
    template: """
              <a class="filter-menu res-display-l" ng-click="toggleFilter(filter)">
                {{item.cn || item.en}} <i class="icon ion-arrow-down-b"></i>
              </a>
              """
    link: (scope, element) ->
      #Should use with ng-repeat
      scope.$watch 'paramUpdateFlag', ->
        scope.item = scope.getFilterItem(scope.filter)
        if scope.item.id
          element.addClass 'active'
        else
          element.removeClass 'active'
  )
  .controller('AppCtrl', ($scope, Single, Popup, Nav, Service, ToggleModal, $timeout, Config, Env, $route, $location) ->

    popupLoginModal = ->
      ToggleModal
        id: 'login'
        template: "<modal navable='modal/login.tpl.html' animation='popup-in-right'></modal>"
        $aniIn: 'from-center'
        $aniOut: 'from-center'
        locals: url:location.href
        controller: 'loginCtrl'
        scope: $scope

    $scope.onTestDevice = ->
      alert(window.innerWidth+'*'+window.innerHeight+'*'+window.devicePixelRatio)

    $scope.onRight = (index)->
      $scope.viewManager.current.scope.$broadcast 'rightButton', index

    $scope.onBack = ->
      Nav.back(name:'my')
    
    #Load meta info first
    $scope.meta = Single('meta', Config.$meta).get()
    $scope.meta.$promise.then ->
      $scope.paramUpdateFlag++

    $scope.isLogin = (popup)->
      login = !!$scope.meta.user
      if not login and popup
        popupLoginModal()
      login

    $scope.noRepeatAndLogin = (id, time)->
      Service.noRepeat(id, time) and $scope.isLogin(yes)


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
        if type isnt pathParam
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
      #do not change env in popup mode
      $scope.env = Env[name] if not Env[name].popup
      last = Nav.last()
      $scope.back = if last then Env[last.name].title else null
      $scope.paramUpdateFlag++

    $scope.$on 'filter.update', (e, name, search)->
      console.log 'filter.update', name, search
      $scope.updateFilters(name, search)

#    $scope.$on 'envUpdate', ->
#      $scope.env = Env[$route.current.name]

    $scope.onSideMenu = (name)->
      Nav.go
        name:name
        search: $scope.updateFilters(name)

    $scope.toggleFilter = (type)->

      if !Service.noRepeat('toggleFilter')
        return

      if !Config.$filter[type]
        console.log "not found", type
        return

      name = $route.current.name
      ToggleModal
        id: 'filters'
        template: "<side-pane position='right' class='pane-filter-bar'></side-pane>"
        $aniIn: 'from-right'
        $aniOut: 'from-right'
        url: "modal/filterBar.tpl.html"
        closeOnBackdrop: yes
        locals:
          title: Config.$filter[type].title
          items: [Config.$filter[type].any].concat $scope.meta[type]
          selected: $scope.updateFilters(name)[type] or 0
        success: (id)->
          param = $scope.updateFilters(name, type, id)
          Nav.go({name:name, search:param})

    $scope.onAll = ->
      name = $route.current.name
      param = $scope.updateFilters(name, 0)
      Nav.go({name:name, search:param})


    $scope.onSearch = (se)->
      name = $route.current.name
      param = $scope.updateFilters(name, 'se', se)
      Nav.go({name:name, search:param})
      $timeout -> document.activeElement.blur()


    $scope.getFilterItem = (type)->
      name = $route.current.name
      selected = $scope.updateFilters(name)[type] or 0
      item = _.find $scope.meta[type], id:parseInt(selected)
      if !item
        item = Config.$filter[type].any
      item

  )
  .controller('loginCtrl', ($scope, Popup, Service, $http, MESSAGE, Url)->

    console.log 'loginCtrl'

    validateMsg =
      email:
        email: MESSAGE.EMAIL_VALID
      minlength:
        password: MESSAGE.MINLEN_PWD
      required:
        username: MESSAGE.REQ_USRNAME
        email: MESSAGE.REQ_EMAIL
        password: MESSAGE.REQ_PWD

    $scope.onLogin = ->
      if Service.noRepeat('login') and Service.validate($scope.loginForm, validateMsg)
        promise = $http.post(Url.login, {username:$scope.username, password:$scope.password})
        Popup.loading promise, showWin:yes
        promise.then(
          (ret)->
            Popup.alert MESSAGE.LOGIN_OK
            $scope.meta.user = ret.data.user
            #save for cross domain use
            if window.SERVER
              localStorage.setItem('csrf', ret.data.csrf)
              $http.defaults.headers.common['X-CSRFToken'] = ret.data.csrf
            $scope.modal.close()
          (ret)->
            msg = if ret.data.error is 'invalid' then MESSAGE.LOGIN_INVALID else MESSAGE.LOGIN_NOK
            Popup.alert msg
        )

    $scope.onRegister = ->
      if Service.noRepeat('login') and Service.validate($scope.registerForm, validateMsg)
        promise = $http.post Url.reg,
          username:$scope.username
          password:$scope.password
          email:$scope.email
        Popup.loading promise, showWin:yes
        promise.then(
          (ret)->
            Popup.alert MESSAGE.REGISTER_OK
            $scope.meta.user = ret.data.user
            #save for cross domain use
            if window.SERVER
              localStorage.setItem('csrf', ret.data.csrf)
              $http.defaults.headers.common['X-CSRFToken'] = ret.data.csrf
            $scope.modal.close()
          (ret)->
            msg = if ret.data.error is 'exist' then MESSAGE.USRNAME_EXIST else MESSAGE.REGISTER_NOK
            Popup.alert msg
        )

  )




