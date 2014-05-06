angular.module('app.pro',[])
  .controller( 'ProsCtrl', ($scope, $controller, Nav, ToggleModal)->
    #extend from ListCtrl
    $scope.listCtrl = $controller('ListCtrl', {$scope:$scope, name: 'pros'})

    $scope.onIdeabook = (obj)->
      Nav.go
        name: 'ideabookDetail'
        param: id:obj.id
        push: yes

    $scope.onUser = (obj)->
      ToggleModal
        id: 'userInfo'
        template: "<side-pane position='right' class='pane-user-info popup-in-right'></side-pane>"
        url: "pro/userInfo.tpl.html"
        closeOnBackdrop: yes
        scope: $scope
        controller: 'UserInfoCtrl'
        locals:
          user: obj


    this
  )
  .controller( 'UserInfoCtrl', ($scope)->

    user = $scope.user
    $scope.profile = user.profile
    $scope.pro = $scope.profile?.pro
    $scope.contact = $scope.pro?.contact


    this
  )