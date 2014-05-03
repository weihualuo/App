angular.module('app.my', [])

  .controller( 'MyCtrl', ($scope, $http, Popup, Env, ToggleModal) ->
    console.log 'Myctrl'

    subviews =
      ideabook:
        name: 'ideabook'
        url: 'ideabook/ideabooks.tpl.html'
        controller: 'myIdeabooksCtrl'
        env:
          right: ['新建灵感集']
      profile:
        name: 'profile'
        url: 'my/profile.tpl.html'
        controller: 'myProfileCtrl'
        class: 'has-form'
        env:
          right: ['更新']

    $scope.myView = subviews.ideabook
    $scope.onItem = (item)->
      $scope.myView = subviews[item]

    $scope.$watch 'myView', (view)->
      $scope.env = view?.env

    if not $scope.meta.$resolved
      Popup.loading $scope.meta.$promise

    loadUserData = (user)->
      $scope.user = user
      if user
        user.profile ?= {}
        user.profile.pro ?= {}

      Env.my.right = if user then ['注销'] else ['登录']
      $scope.$emit 'envUpdate'

    $scope.$watch 'meta.user', loadUserData

    $scope.$on '$viewContentLoaded', (e)->
      if e.targetScope is $scope
        $scope.meta.$promise.then -> $scope.isLogin(yes)

    #right button of main bar
    $scope.$on 'rightButton', (e, index)->
      if $scope.isLogin(yes) then $scope.onLogout()

    $scope.onLogout = ->
      $http.post('/auth/logout').then ->
        $scope.meta.user = null


    $scope.onRight = (index)->

    $scope.onLeft = ()->

    $scope.onMenu = ->
      ToggleModal
        id: 'myMenu'
        template: "<side-pane position='right' class='pane-my-menu popup-in-right'></side-pane>"
        url: "my/myMenu.tpl.html"
        closeOnBackdrop: yes
        scope: $scope
        success: (id)->

    $scope.onEditProfile = ->
      ToggleModal
        id: 'editProfile'
        template: "<modal navable='my/profile.tpl.html' animation='popup-in-right' class='fade-in-out profile-win'></modal>"
        controller: 'myProfileCtrl'
        scope: $scope

    this
  )
  .controller('myIdeabooksCtrl', ($scope, Restangular)->
    console.log 'myIdeabooksCtrl'

    $scope.objects = []
    $scope.$watch 'user', (user)->
      if user
        param = author: user.id
        Restangular.all('ideabooks').withHttpConfig({cache: false}).getList(param).then(
          (data)->
            $scope.objects = data
        ).finally ->
          $scope.objects.$resolved = true

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
      promise = Service.uploadFile('image', $scope.profile.image, url, 'PATCH')
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