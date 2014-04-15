angular.module('app.home', ['restangular'])

  .directive('imageThumb', (ImageUtil)->

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
          image.src = ImageUtil.thumb(scope.obj)
          image.onload = ->
            element.append image
          #image.onerror = ->
            #console.log "onerror", scope.obj.id
      element.triggerHandler 'dynamic.add'

  )
  .controller( 'PhotoCtrl', ($scope, $controller, $element, $timeout, $filter, Many, Popup, Nav, TogglePane, MESSAGE) ->
    console.log 'PhotoCtrl'

    #extend from ListCtrl
    $controller('ListCtrl', {$scope:$scope, name: 'photos'})


    $scope.onImageView = (e)->

      #Delegate mode in large list
      item = e.target
      if item.tagName is 'IMG'
        item = item.parentNode
        obj = angular.element(item).scope().obj
        data =
          rect: item.getBoundingClientRect()
          index: $scope.objects.indexOf(obj)
          listScope: $scope
        #goDetail data, data.index
        Nav.go('photoDetail', null, null, null, data)
        return

    $scope.$on 'gallery.slide', (e, index, x)->
      if $scope.haveMore and index+6 > $scope.objects.length
        $scope.$emit 'scroll.moreStart'

  )
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
      Nav.go('productDetail', id:obj.id)
  )
  .controller( 'ProsCtrl', ($scope, $controller, Nav)->
    #extend from ListCtrl
    $controller('ListCtrl', {$scope:$scope, name: 'pros'})

  )
  .controller( 'IdeabookCtrl', ($scope, $controller, Nav)->
    #extend from ListCtrl
    $controller('ListCtrl', {$scope:$scope, name: 'ideabooks'})

  )
  .controller( 'AdviceCtrl', ($scope, $timeout, $filter, Many, Popup, MESSAGE) ->
    console.log 'AdviceCtrl'

  )
  .controller( 'MyCtrl', ($scope, $timeout, $filter, Many, Popup, MESSAGE) ->
    console.log 'Myctrl'

  )


