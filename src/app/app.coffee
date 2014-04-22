angular.module( 'app', [ 'ngRoute', 'ngTouch', 'ngAnimate',
                         'templates-app', 'templates-common',
                         'Model', 'app.utils', 'app.home', 'app.photo', 'app.product', 'app.ideabook', 'app.discussion',
                         'CacheView', 'Service', 'Popup', 'Scroll', 'Widget'
                         'MESSAGE'
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
    .when( '/photoInfo',
      name: 'photoInfo'
      controller: 'PhotoInfoCtrl'
      templateUrl: 'photo/photoInfo.tpl.html'
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
      class: 'no-sub'
      cache: yes
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
      templateUrl: 'home/ideabooks.tpl.html'
      cache: yes
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
      templateUrl: 'home/my.tpl.html'
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
      filters: ['style', 'room']
      title: '灵感集'
    advice:
      title: '建议'
    my:
      title: '我的家居'
    productDetail:
      title: '产品详情'
    photoDetail:
      style: opacity:'0.7'
  )
  .run( ($location, $document)->
    # simulate html5Mode
    if !location.hash
      $location.path(location.pathname)

    #prevent webkit drag
    $document.on 'touchmove mousemove', (e)->e.preventDefault()
  )
  .controller('AppCtrl', ($scope, Single, Popup, Nav, Service, ToggleModal, $timeout, Config, Env, $route) ->

    popupLoginModal = ->
      ToggleModal
        id: 'login'
        template: "<div navable='template' animation='popup-in-right' class='popup-win fade-in-out'></div>"
        locals: url:location.href
        controller: 'loginCtrl'
        scope: $scope

    $scope.onTestDevice = ->
      alert(window.innerWidth+'*'+window.innerHeight+'*'+window.devicePixelRatio)

    $scope.onButton = (id)->
      if $scope.isLogin(yes)
        no
    
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
        hash: 'filters'
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
        $http.post('/auth/login', {username:$scope.username, password:$scope.password}).then(
          (ret)->
            Popup.alert MESSAGE.LOGIN_OK
            $scope.meta.user = ret.data.user
            $scope.modal.close()
            console.log "success", $scope.meta.user
          (ret)->
            if ret.data.error is 'invalid'
              Popup.alert MESSAGE.LOGIN_NOK
            console.log "fail", ret
        )

    $scope.onRegister = ->
      if Service.noRepeat('login') and validate($scope.registerForm)
        console.log "ok, now register"
        $http.post('/auth/register',
          username:$scope.username
          password:$scope.password
          email:$scope.email
        ).then(
          (ret)->
            Popup.alert MESSAGE.REGISTER_OK
            $scope.meta.user = ret.data.user
            $scope.modal.close()
            console.log "success", $scope.meta.user
          (ret)->
            if ret.data.error is 'exist'
              Popup.alert MESSAGE.USRNAME_EXIST
            console.log "fail", ret
        )

  )




