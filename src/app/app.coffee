angular.module( 'app', [ 'ngRoute', 'ngTouch', 'ngAnimate',
                         'templates-app', 'templates-common', 'Model', 'MESSAGE'
                         'app.utils', 'app.home', 'app.photo', 'app.product', 'app.ideabook', 'app.my',
                         'CacheView', 'Service', 'Popup', 'Scroll', 'Widget'
])
  .config( ($routeProvider, $compileProvider, $httpProvider) ->
#    // Needed for phonegap routing
    $compileProvider.aHrefSanitizationWhitelist(/^\s*(https?|ftp|mailto|file|tel):/)
    #$locationProvider.html5Mode(true)
    $httpProvider.defaults.xsrfHeaderName = 'X-CSRFToken'
    $httpProvider.defaults.xsrfCookieName = 'csrftoken'

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
      templateUrl: 'home/pros.tpl.html'
      cache: yes
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
      controller: 'IdeabookUnitCtrl'
      templateUrl: 'ideabook/ideabookUnit.tpl.html'
      class: 'no-background no-header no-side'
    )
    .when( '/advice'
      name: 'advice'
      controller: 'AdviceCtrl'
      templateUrl: 'home/advice.tpl.html'
      class: 'no-sub'
      cache: yes
    )
    .when( '/my'
      name: 'my'
      controller: 'MyCtrl'
      templateUrl: 'my/my.tpl.html'
      class: 'no-sub'
      cache: yes
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
      filters: []
      title: '灵感集'
    advice:
      title: '建议'
    my:
      title: '我的家居'
    productDetail:
      title: '产品详情'
      noSide: true
      back: '产品'
    photoDetail:
      back: '照片'
      #noSide: true
      #noHeader: true
    ideabookDetail:
      noSide: true
      back: '灵感集'
    ideabookUnit:
      noSide: true
      #noHeader: true
  )
  .run( ($location, $document)->
    # simulate html5Mode
    if !location.hash
      $location.path(location.pathname)

    #prevent webkit drag
    $document.on 'touchmove mousemove', (e)->e.preventDefault()
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
  .controller('AppCtrl', ($scope, Single, Popup, Nav, Service, ToggleModal, $timeout, Config, Env, $route) ->

    popupLoginModal = ->
      ToggleModal
        id: 'login'
        template: "<modal navable='template' animation='popup-in-right' class='fade-in-out'></modal>"
        locals: url:location.href
        controller: 'loginCtrl'
        scope: $scope

    $scope.onTestDevice = ->
      alert(window.innerWidth+'*'+window.innerHeight+'*'+window.devicePixelRatio)

    $scope.onRight = (id)->
      if $scope.isLogin(yes)
        no

    $scope.onBack = ->
      Nav.back(name:'photos')
    
    #Load meta info first
    $scope.meta = Single('meta', Config.$meta).get()
    $scope.meta.$promise.then ->
      $scope.paramUpdateFlag++

    $scope.isLogin = (popup)->
      login = !!$scope.meta.user
      if not login and popup
        popupLoginModal()
      login

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

    $scope.$on 'envUpdate', ->
      $scope.env = Env[$route.current.name]

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
        template: "<side-pane position='right' class='pane-filter-bar popup-in-right'></side-pane>"
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
  .controller('loginCtrl', ($scope, Popup, Service, $http, MESSAGE)->

    console.log 'loginCtrl'
    $scope.template = 'modal/login.tpl.html'

    validateMsg =
      email:
        email: MESSAGE.EMAIL_VALID
      minlength:
        password: MESSAGE.MINLEN_PWD
      required:
        username: MESSAGE.REQ_USRNAME
        email: MESSAGE.REQ_EMAIL
        password: MESSAGE.REQ_PWD

    popupMsg = ($error)->
      for error, inputs of $error
        try
          if msg =  validateMsg[error][inputs[0].$name]
            break
        catch error
          continue
      Popup.alert msg

    validate = (form)->
      console.log form
      if form.$invalid
        popupMsg(form.$error)
        return false
      return true

    $scope.onLogin = ->
      if Service.noRepeat('login') and validate($scope.loginForm)
        console.log "ok, now login"
        promise = $http.post('/auth/login', {username:$scope.username, password:$scope.password})
        Popup.loading promise, showWin:yes
        promise.then(
          (ret)->
            Popup.alert MESSAGE.LOGIN_OK
            $scope.meta.user = ret.data.user
            $scope.modal.close()
            console.log "success", $scope.meta.user
          (ret)->
            msg = if ret.data.error is 'invalid' then MESSAGE.LOGIN_INVALID else MESSAGE.LOGIN_NOK
            Popup.alert msg
            console.log "fail", ret
        )

    $scope.onRegister = ->
      if Service.noRepeat('login') and validate($scope.registerForm)
        console.log "ok, now register"
        promise = $http.post '/auth/register',
          username:$scope.username
          password:$scope.password
          email:$scope.email
        Popup.loading promise, showWin:yes
        promise.then(
          (ret)->
            Popup.alert MESSAGE.REGISTER_OK
            $scope.meta.user = ret.data.user
            $scope.modal.close()
            console.log "success", $scope.meta.user
          (ret)->
            msg = if ret.data.error is 'exist' then MESSAGE.USRNAME_EXIST else MESSAGE.REGISTER_NOK
            Popup.alert msg
            console.log "fail", ret
        )

  )




