angular.module('app.pro',[])

  .controller( 'ProsCtrl', ($scope, $controller, Nav)->
    $scope.listCtrl = $controller('ListCtrl', {$scope:$scope, name: 'pros'})

    $scope.onIdeabook = (obj)->
      Nav.go
        name: 'ideabookDetail'
        param: id:obj.id
        push: yes


    $scope.onUser = (id)->
      Nav.go
        name: 'userDetail'
        param: id:id
        push: yes

    this
  )
  .controller( 'UserDetailCtrl', ($scope, Many, $routeParams, Popup)->

    console.log 'UserDetailCtrl'
    collection = Many('pros')

    user = null
    $scope.$on '$scopeUpdate', ->
      $scope.user = user = collection.get parseInt($routeParams.id)
      Popup.loading(user.$promise) if not user.$resolved

      user.$promise.then ->
        $scope.profile = user.profile
        $scope.pro = $scope.profile?.pro
        $scope.contact = $scope.pro?.contact

    this
  )