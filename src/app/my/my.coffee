angular.module('app.my', [])

  .controller( 'MyCtrl', ($scope, $http) ->
    console.log 'Myctrl'

    $scope.subviews =
      ideabook:
        name: 'ideabook'
        url: 'ideabook/ideabooks.tpl.html'
        controller: 'myIdeabooksCtrl'
      profile:
        name: 'profile'
        url: 'my/profile.tpl.html'
        controller: 'myProfileCtrl'


    $scope.user = $scope.meta.user
    $scope.myView = $scope.subviews.ideabook

    $scope.onItem = (item)->
      $scope.myView = $scope.subviews[item]

    $scope.onLogout = ->
      $http.post('/auth/logout').then ->
        $scope.meta.user = null
    this
  )
  .controller('myIdeabooksCtrl', ($scope, Restangular)->
    console.log 'myIdeabooksCtrl'

    $scope.objects = []
    param = author: $scope.user.id
    Restangular.all('ideabooks').withHttpConfig({cache: false}).getList(param).then (data)->
      $scope.objects = data

    this
  )
  .controller('myProfileCtrl', ($scope)->

    this
  )