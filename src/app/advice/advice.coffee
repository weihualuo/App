angular.module('app.advice', [])
  .controller( 'AdviceCtrl', ($scope, $controller, Nav, Popup, MESSAGE) ->
    console.log 'AdviceCtrl'
    $scope.listCtrl = $controller('ListCtrl', {$scope:$scope, name: 'advices'})

    $scope.onAdviceView = (obj)->
      Nav.go
        name: 'adviceDetail'
        param: id:obj.id
        push: yes
    this

  )
  .controller('AdviceDetailCtrl', ($scope, Many, Nav, $routeParams, Popup)->
    console.log 'AdviceDetailCtrl'
    # Init locals
    collection = Many('advices')
    obj = null

    $scope.$on '$scopeUpdate', ->
      $scope.obj = obj = collection.get parseInt($routeParams.id)
      if not obj.$resolved
        #Loading will end automatically when promise resolved or rejected
        Popup.loading obj.$promise
      #reset the tab state
      obj.$promise.then ->

    $scope.onBack = ->
      Nav.back({name:'advices'})
    this
  )