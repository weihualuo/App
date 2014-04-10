angular.module('app.home', ['Gallery', 'restangular'])

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
  .controller( 'PhotoCtrl', ($scope, $controller, $timeout, $filter, Many, Popup, TogglePane, MESSAGE) ->
    console.log 'PhotoCtrl'

    #extend from ListCtrl
    $controller('ListCtrl', $scope:$scope)

    $scope.onImageInfo = (index)->
      TogglePane
        id: 'infoView'
        template: "<side-pane position='left' class='pane-image-info popup-in-left'></side-pane>"
        url: "modal/imageInfo.tpl.html"
        hash: 'info'
        locals:
          image: $scope.objects[index]

    item = null
    $scope.onImageView = (e)->
      #Delegate mode in large list
      item = e.target
      if item.tagName is 'IMG'
        item = item.parentNode
        obj = angular.element(item).scope().obj
        TogglePane
          id: 'imageView'
          template: "<gallery-view></gallery-view>"
          hash: 'gallery'
          backdrop: false
          scope: $scope
          locals:
            index: $scope.objects.indexOf(obj)
            rect:  item.getBoundingClientRect()

    $scope.$on 'gallery.slide', (e, index, x)->
      #console.log "gallery.slide", index, x
      item = item.previousElementSibling if x > 0
      item = item.nextElementSibling if x < 0
      if $scope.haveMore and index+6 > $scope.objects.length
        $scope.$emit 'scroll.moreStart'

    $scope.getItemRect = ->
      scroll = $scope.$scroll
      top = scroll.scroller.getValues().top
      itemTop = item.offsetTop
      itemHeight = item.offsetHeight
      containerHeight = scroll.container.clientHeight
      #above
      if top > itemTop
        scroll.scroller.scrollTo(0, itemTop)
      #below
      else if top < itemTop+itemHeight-containerHeight
        scroll.scroller.scrollTo(0, itemTop+itemHeight-containerHeight)

      item.getBoundingClientRect()

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
    $controller('ListCtrl', $scope:$scope)

    $scope.onProductView = (e, obj)->
      Nav.go('/productView', id:obj.id)
#      TogglePane
#        id: 'productView'
#        template: "<product-view></product-view>"
#        hash: 'productView'
#        backdrop: false
#        root:
#        scope: $scope
#        locals:
#          obj: obj

  )
  .controller( 'AdviceCtrl', ($scope, $timeout, $filter, Many, Popup, MESSAGE) ->
    console.log 'AdviceCtrl'

  )
  .controller( 'MyCtrl', ($scope, $timeout, $filter, Many, Popup, MESSAGE) ->
    console.log 'Myctrl'

  )


