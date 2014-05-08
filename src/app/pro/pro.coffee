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
    collection = Many('pros')

    user = null
    $scope.$on '$scopeUpdate', ->
      $scope.user = user = collection.get parseInt($routeParams.id)
      Popup.loading(user.$promise) if not user.$resolved

      user.$promise.then ->
        $scope.profile = user.profile
        $scope.pro = $scope.profile?.pro
        $scope.contact = $scope.pro?.contact

    $scope.$on 'content.closed', ->
      #unregister animation hook
      ctrl.unregister()
      Nav.back name:'pros'

    $scope.$on 'parent.event', (e, event)->
      Nav.back name:'pros'

    $scope.onIdeabook = (id)->
      Nav.go
        name:  'ideabookDetail'
        param: id:id
        push: yes

    this
  )