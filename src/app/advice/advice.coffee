angular.module('app.advice', [])
  .controller( 'AdviceCtrl', ($scope, $controller, Nav, ToggleModal, Popup, MESSAGE) ->
    console.log 'AdviceCtrl'
    $scope.listCtrl = $controller('ListCtrl', {$scope:$scope, name: 'advices'})

    $scope.onAdviceView = (obj)->
      Nav.go
        name: 'adviceDetail'
        param: id:obj.id
        push: yes
    this

  )
  .controller('AdviceDetailCtrl', ($scope, Many, Nav, $routeParams, MESSAGE, Popup, ToggleModal)->
    console.log 'AdviceDetailCtrl'
    # Init locals
    collection = Many('advices')
    obj = null

    $scope.$on '$scopeUpdate', ->
      $scope.obj = obj = collection.get parseInt($routeParams.id)
      Popup.loading(obj.$promise) if not obj.$resolved

    $scope.onBack = ->
      Nav.back({name:'advices'})

    $scope.onComment = ->
      if not $scope.isLogin(yes) then return
      ToggleModal
        id: 'comment'
        template: "<modal animation='popup-in-right' class='fade-in-out'></modal>"
        url: "modal/comment.tpl.html"
        locals:
          title: MESSAGE.COMMENT
        success: (comment)->
          if comment
            Popup.loading collection.new(
              body: comment
              reply: obj.id
            ).then (data)->
              obj.replies.unshift data
              null

    #right button of main bar
    $scope.$on 'rightButton', $scope.onComment

    this
  )