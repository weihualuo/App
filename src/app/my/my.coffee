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
      $scope.profile = $scope.user?.userprofile or {}
      if $scope.profile.image
        $scope.profile.image = $scope.meta.imgbase + $scope.profile.image
      else
        $scope.profile.image = "/m/assets/img/user.gif"
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

    data = $scope.data = {}
    $scope.$watch 'user', (user)->
      if user
        profile = $scope.profile
        data.name = user.first_name
        data.email = user.email
        data.gender = profile.gender
        data.location= _.find($scope.meta.location, id: profile.location)
        data.desc = profile.desc

    uploadImage = (id)->
      url = '/api/profile/'+ id
      promise = Service.uploadFile('image', data.image, url, 'PATCH')
      promise.then(
        (ret)->
          data.image = null
          $scope.profile.image = $scope.meta.imgbase + JSON.parse(ret).image
          Popup.alert MESSAGE.UPDATE_OK
          $scope.modal.close()
        (ret)->
          Popup.alert MESSAGE.UPLOAD_FAILED
      )
      promise

    $scope.onSubmit = ->

      console.log $scope.form, $scope.formPro

      validateMsg =
        email:
          email: MESSAGE.EMAIL_VALID
        required:
          email: MESSAGE.REQ_EMAIL

      if Service.noRepeat('updateProfile') and Service.validate($scope.form, validateMsg)

        if $scope.form.$dirty or data.image
          param = {}
          param.first_name = data.name
          param.email = data.email
          param.profile = profile = {}
          profile.gender = data.gender
          # Set if selected
          profile.location = data.location.id if data.location
          profile.desc = data.desc
          # Set if no profile created
          profile.status = 1 unless $scope.profile.status

          promise = $http.post('/auth/update', param).then(
            (ret)->
              user = ret.data.user
              $scope.meta.user = user
              $scope.form.$setPristine()
              if data.image
                # Retrur a chained promise
                return uploadImage(user.userprofile.id)
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