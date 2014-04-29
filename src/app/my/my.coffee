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
      $scope.profile.image ?= "/m/assets/img/user.gif"
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
  .controller('myProfileCtrl', ($scope)->

    data = $scope.data = {}
    $scope.$watch 'user', (user)->
      if user
        profile = $scope.profile
        data.name = user.first_name
        data.email = user.email
        data.gender = profile.gender
        data.location= profile.location
        data.desc = profile.desc
    this
  )