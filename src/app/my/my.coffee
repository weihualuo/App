angular.module('app.my', [])

  .controller( 'MyCtrl', ($scope, $http, Popup, Env) ->
    console.log 'Myctrl'

    subviews =
      ideabook:
        name: 'ideabook'
        url: 'ideabook/ideabooks.tpl.html'
        controller: 'myIdeabooksCtrl'
      profile:
        name: 'profile'
        url: 'my/profile.tpl.html'
        controller: 'myProfileCtrl'

    $scope.myView = subviews.ideabook
    $scope.onItem = (item)->
      $scope.myView = subviews[item]

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

    $scope.$on 'rightButton', (e, index)->
      if $scope.isLogin(yes) then $scope.onLogout()

    $scope.onLogout = ->
      $http.post('/auth/logout').then ->
        $scope.meta.user = null

    this
  )
  .controller('myIdeabooksCtrl', ($scope, Restangular)->
    console.log 'myIdeabooksCtrl'

    $scope.objects = []
    $scope.$watch 'user', (user)->
      if user
        param = author: user.id
        Restangular.all('ideabooks').withHttpConfig({cache: false}).getList(param).then (data)->
          $scope.objects = data

    this
  )
  .controller('myProfileCtrl', ($scope, $http, Service, MESSAGE, Popup, $timeout)->

    data = $scope.data = {}
    $scope.$watch 'user', (user)->
      if user
        profile = $scope.profile
        data.name = user.first_name
        data.email = user.email
        data.gender = profile.gender
        data.location= _.find($scope.meta.location, id: profile.location)
        data.desc = profile.desc

    # timeout to digest over
    afterUpdate = -> $timeout ->
      if data.image
        url = '/api/profile/'+ $scope.profile.id
        Service.uploadFile('image', data.image, url, 'PATCH')

    $scope.onSubmit = ->

      console.log $scope.form
      validateMsg =
        email:
          email: MESSAGE.EMAIL_VALID
        required:
          email: MESSAGE.REQ_EMAIL

      if Service.noRepeat('updateProfile') and Service.validate($scope.form, validateMsg)

        if $scope.form.$dirty
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

          promise = $http.post '/auth/update', param
          Popup.loading promise, showWin:yes
          promise.then(
            (ret)->
              console.log ret
              Popup.alert MESSAGE.UPDATE_OK
              $scope.meta.user = ret.data.user
              $scope.form.$setPristine()
              afterUpdate()
            (ret)->
              console.log ret
              #django backend use diffrent email validation strategy with angular
              msg = if ret.data.error?.email then MESSAGE.EMAIL_VALID else MESSAGE.SUBMIT_FAILED
              Popup.alert msg
          )
        else
          afterUpdate()

    this
  )