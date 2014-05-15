angular.module('app.pro',[])

  .filter( 'categoryName', (Single)->
    meta = Single('meta').get()
    (user)->
      id = user?.profile?.pro?.category
      ca = _.find(meta.category, id:id)
      ca?.cn
  )

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
  .controller( 'UserDetailCtrl', ($scope, Many, $routeParams, Popup, Nav)->

    console.log 'UserDetailCtrl'
    ctrl = this

    user = null
    $scope.$on '$scopeUpdate', ->
      $scope.user = user = Many('pros').get parseInt($routeParams.id)

      user.$promise.then ->
        $scope.profile = user.profile
        $scope.pro = $scope.profile?.pro
        $scope.contact = $scope.pro?.contact


    $scope.onBack = -> Nav.back name:'pros'

    $scope.$on 'content.closed', ->
      #unregister animation hook
      ctrl.unregister()
      $scope.onBack()

    $scope.$on 'parent.event', $scope.onBack

    $scope.onIdeabook = (id)->
      Nav.go
        name:  'ideabookDetail'
        param: id:id

    this
  )