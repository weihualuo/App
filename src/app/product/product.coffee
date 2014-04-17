
angular.module('app.product', [])

  .directive('productThumb', (ImageUtil)->

    restrict:'C'
    link: (scope, element)->

      image = null
      element.on 'dynamic.remove', ->
        #console.log "dynamic.remove", scope.obj.id
        if image
          image.remove()
          image = null
      element.on 'dynamic.add', ->
        #console.log "dynamic.add", scope.obj.id
        if not image
          image = new Image()
          image.src = ImageUtil.productThumb(scope.obj.params[0])
          image.onload = ->
            element.prepend image
      #image.onerror = ->
      #console.log "onerror", scope.obj.id
      element.triggerHandler 'dynamic.add'

  )
  .directive('productView', (ImageUtil)->
    restrict: 'E'
    replace: true
    template: """
              <div class="product-view">
              <img ng-src="{{src}}">
              <h5 class='title'>{{obj.title}}</h5>
              <p class='desc'>{{obj.desc}}</p>
              </div>
              """
    link: (scope, element, attr) ->
      obj = scope.obj
      scope.src = ImageUtil.best(obj.params[0])

  )
  .controller( 'ProductCtrl', ($scope, $controller, Nav)->
    #extend from ListCtrl
    $controller('ListCtrl', {$scope:$scope, name: 'products'})

    $scope.onProductView = (e, obj)->
      Nav.go
        name:'productDetail'
        param: id:obj.id
        push: yes
    this
  )

  .controller( 'ProductDetailCtrl', ($scope, $routeParams, Many, ImageUtil, Popup, Nav) ->

    @transitIn = @transitOut ='from-right'

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

    this
  )