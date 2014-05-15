angular.module('app.my', [])

  .directive('profileImage', (Single)->
    (scope, element, attr)->

      meta = Single('meta').get()

      scope.$watch attr.profileImage, (obj)->
        image = if obj then (obj.image or (if obj.profile then (obj.profile.image or obj.profile.pro?.image) else null)) else null
        src = if image then meta.imgbase + image else '/m/assets/img/user.gif'
        attr.$set 'src', src
  )

  .controller( 'MyCtrl', ($scope, $http, Popup, Env, ToggleModal) ->
    console.log 'Myctrl'

    subviews =
      ideabook:
        name: 'ideabook'
        url: 'my/myIdeabooks.tpl.html'
        controller: 'myIdeabooksCtrl'
        cache: yes

      bookmark:
        name: 'bookmark'
        url: 'my/myBookmark.tpl.html'
        controller: 'myBookmarkCtrl'

      topic:
        name: 'topic'
        url: 'advice/advices.tpl.html'
        controller: 'myTopicCtrl'
        cache: yes

      upload:
        name: 'upload'
        url: 'my/myUpload.tpl.html'
        controller: 'myUploadCtrl'

    $scope.myView = subviews.ideabook
    $scope.onItem = (item)->
      $scope.myView = subviews[item]

    if not $scope.meta.$resolved
      Popup.loading $scope.meta.$promise

    loadUserData = (user)->
      $scope.user = user
      if user
        user.profile ?= {}
        user.profile.pro ?= {}

      Env.my.right = if user then ['注销'] else ['登录']

    $scope.$watch 'meta.user', loadUserData

    $scope.$on '$viewContentLoaded', (e)->
      if e.targetScope.$parent is $scope
        e.stopPropagation()
        if not $scope.user
          $scope.meta.$promise.then -> $scope.isLogin(yes)

    #right button of main bar
    $scope.$on 'rightButton', (e, index)->
      if $scope.isLogin(yes) then $scope.onLogout()

    $scope.onLogout = ->
      $http.post('/auth/logout').then ->
        $scope.meta.user = null


    $scope.onRight = (index)->
      $scope.viewManager.current.scope.$broadcast 'onRight', index

    $scope.onLeft = ()->

    $scope.onMenu = ->
      ToggleModal
        id: 'myMenu'
        template: "<side-pane close-on-resize position='right' class='pane-my-menu popup-in-right'></side-pane>"
        url: "my/myMenu.tpl.html"
        closeOnBackdrop: yes
        scope: $scope

    $scope.onEditProfile = ->
      ToggleModal
        id: 'editProfile'
        template: "<modal navable='my/profile.tpl.html' animation='popup-in-right' class='fade-in-out profile-win'></modal>"
        controller: 'myProfileCtrl'
        scope: $scope

    $scope.onUpload = ->
      ToggleModal
        id: 'upload'
        template: "<modal class='fade-in-out profile-win'></modal>"
        url: 'my/myUpload.tpl.html'
        controller: 'myUploadCtrl'
        scope: $scope
    this
  )
  .controller('myIdeabooksCtrl', ($scope, $controller, Nav)->
    console.log 'myIdeabooksCtrl'

    listCtrl = $controller 'ListCtrl', {$scope:$scope, name:'ideabooks'}
    $scope.$watch 'meta.user', (user)->
      if user
        listCtrl.reload(author:user.id, 'my')

    $scope.$on 'scroll.reload', ->
      $scope.myView.left = $scope.user.username + "的灵感集(#{$scope.objects.length})"

    $scope.onIdeaBookView = (obj)->
      Nav.go
        name: 'ideabookDetail'
        param: id:obj.id
        push: yes

    this
  )
  .controller('myProfileCtrl', ($scope, $http, Service, MESSAGE, Popup)->

    $scope.$watch 'user', (user)->
      if not user then return
      $scope.data = angular.copy user
      $scope.profile = $scope.data.profile
      $scope.pro = $scope.profile.pro
      $scope.pro.contact ?= {}

      #Conver some values
      if user.profile.location
        $scope.profile.location= _.find($scope.meta.location, id: user.profile.location)
      $scope.profile.image = null
      if user.profile.pro.category
        $scope.pro.category = _.find($scope.meta.category, id: user.profile.pro.category)

    uploadImage = (id)->
      url = '/api/profile/'+ id
      promise = Service.uploadFile({image: $scope.profile.image}, url, 'PATCH')
      promise.then(
        (ret)->
          $scope.profile.image = null
          $scope.user.profile.image = JSON.parse(ret).image
          Popup.alert MESSAGE.UPDATE_OK
          $scope.modal.close()
        (ret)->
          Popup.alert MESSAGE.UPLOAD_FAILED
      )
      promise


    validateMsg =
      email:
        email: MESSAGE.EMAIL_VALID
      required:
        email: MESSAGE.REQ_EMAIL
        address: MESSAGE.REQ_ADDR
        phone: MESSAGE.REQ_PHONE
      url:
        link: MESSAGE.URL_VALID

    validateForms = ->
      if Service.validate($scope.form, validateMsg) and
          (not $scope.formPro or Service.validate($scope.formPro, validateMsg)) and
          (not $scope.formCon or Service.validate($scope.formCon, validateMsg))
        return yes
      return no

    setPristine = ->
      $scope.form.$setPristine()
      $scope.formPro?.$setPristine()
      $scope.formCon?.$setPristine()

    isDirty = ->
      $scope.form.$dirty or $scope.formPro?.$dirty or $scope.formCon?.$dirty or $scope.profile.image

    $scope.onSubmit = ->

      console.log $scope.form, $scope.formPro, $scope.formCon
      console.log $scope.data, $scope.pro, $scope.con

      if Service.noRepeat('updateProfile') and validateForms() and isDirty()

        param = angular.copy($scope.data)
        #Conver some values
        if $scope.profile.location
          param.profile.location = $scope.profile.location.id
        # Set if no profile created
        if not $scope.profile.status
          param.profile.status = 1

        if not $scope.formCon or $scope.formCon.$pristine
          delete param.profile.pro.contact
          if not $scope.formPro or $scope.formPro.$pristine
            delete param.profile.pro

        if param.profile.pro?.category
          param.profile.pro.category = param.profile.pro.category.id

        promise = $http.post('/auth/update', param).then(
          (ret)->
            user = ret.data.user
            $scope.meta.user = user
            setPristine()
            if $scope.profile.image
              # Retrur a chained promise
              return uploadImage(user.profile.id)
            else
              Popup.alert MESSAGE.UPDATE_OK
              $scope.modal.close()
              null
          (ret)->
            console.log ret
            #django backend use diffrent email validation strategy with angular
            msg = if ret.data.error?.email then MESSAGE.EMAIL_VALID else MESSAGE.SUBMIT_FAILED
            Popup.alert msg
            null
        )
        Popup.loading promise, showWin:yes

    this
  )
  .controller('myBookmarkCtrl', ($scope)->
    this
  )
  .controller('myTopicCtrl', ($scope, $controller, Nav)->

    listCtrl = $controller 'ListCtrl', {$scope:$scope, name:'advices'}
    $scope.$watch 'meta.user', (user)->
      listCtrl.reload(author:user.id, 'my')

    $scope.onAdviceView = (obj)->
      Nav.go
        name: 'adviceDetail'
        param: id:obj.id
        push: yes
    this
  )
  .controller('myUploadCtrl', ($scope, $controller, Service, Popup, MESSAGE)->

    $scope.data = data = {}
    $scope.user = $scope.meta.user

    $controller('addIdeabookCtrl', {$scope: $scope})

    addToIdeabook = (image)->
      if $scope.ideabook.id or $scope.title
        $scope.image = image
        $scope.onSave()
      else
        Popup.alert MESSAGE.SAVE_OK
        $scope.modal.close()
        null

    uploadImage = (params)->
      promise = Service.uploadFile(params, '/api/photos')
      promise.then(
        (ret)->
          console.log ret
          return addToIdeabook(JSON.parse(ret))

        ()->
          Popup.alert MESSAGE.UPLOAD_FAILED
          null
      )

    $scope.onUpload = ->
      if not Service.noRepeat('upload') then return
      if not data.image then return Popup.alert MESSAGE.REQ_IMAGE

      params = {}
      for key, value of data
        params[key] = value
      #Conver some values
      if data.style
        params.style = data.style.id
      if data.room
        params.room = data.room.id

      promise = uploadImage(params)
      Popup.loading promise, showWin:yes

    this
  )