angular.module('app.detail', [])

  .controller( 'ProductDetailCtrl', ($scope, $routeParams, Many, ImageUtil, Popup, Nav) ->

    console.log 'ProductDetailCtrl'
    # Init locals
    collection = Many('products')
    obj = null

    $scope.$on '$scopeUpdate', ->
      $scope.obj = obj = collection.get parseInt($routeParams.id)
      if not obj.$resolved
        #Loading will end automatically when promise resolved or rejected
        Popup.loading obj.$promise
      #reset the tab state
      obj.$promise.then ->
        $scope.src = ImageUtil.last(obj.params[0])

    $scope.onBack = ->
      Nav.back({name:'products'})

  )


