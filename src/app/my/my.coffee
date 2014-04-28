angular.module('app.my', [])

  .controller( 'MyCtrl', ($scope, $http) ->
    console.log 'Myctrl'
    $scope.onLogout = ->
      $http.post('/auth/logout').then ->
        $scope.meta.user = null
    this
  )