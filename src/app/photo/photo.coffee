
angular.module('app.photo', ['Gallery'])
  .directive('rectTransform', (PrefixedStyle, PrefixedEvent)->

    setTransform = (el, rect)->
      offsetX = rect.left+rect.width/2-window.innerWidth/2
      offsetY = rect.top+rect.height/2-window.innerHeight/2
      ratioX = rect.width/window.innerWidth
      ratioY = rect.height/window.innerHeight
      PrefixedStyle el, 'transform', "translate3d(#{offsetX}px, #{offsetY}px, 0) scale3d(#{ratioX}, #{ratioY}, 0)"

    (scope, element)->
      raw = element[0]
      if scope.rect
        setTransform raw, scope.rect
        element.ready ->
          PrefixedStyle raw, 'transition', 'all ease-in 300ms'
          PrefixedStyle raw, 'transform', null

      PrefixedEvent element, "TransitionEnd", ->
        console.log "end"
        PrefixedStyle raw, 'transition', null
        #scope.$emit 'destroyed'

      scope.onClose = (index)->
        PrefixedStyle raw, 'transition', 'all ease-in 300ms'
        setTransform raw, scope.getItemRect(index)

  )
  .directive('galleryView', ($controller)->
    restrict: 'C'
    link: (scope, element, attr) ->

      ctrl = null
      slides = element[0].firstElementChild
      scope.$on 'scroll.reload', ->
        if not ctrl
          ctrl = $controller('GalleryCtrl', $scope:scope)
          ctrl.initSlides(angular.element(slides))
          ctrl.onSlide()
  )

  .controller( 'PhotoDetailCtrl', ($scope, $controller, $element, $timeout, Nav, Env)->
    #extend from ListCtrl
    $controller('ListCtrl', {$scope:$scope, name: 'photos'})
    angular.extend($scope, Nav.data())
    $scope.index ?= 0
    listScope = $scope.listScope

    Env.photoDetail.noHeader = false
    Env.photoDetail.noSide = false
    $timeout (->
      Env.photoDetail.noHeader = true
      Env.photoDetail.noSide = true
      $scope.$emit('envUpdate')
    ), 1000

    $scope.getItemRect = (index)->
      if listScope
        listScope.getItemRect(index)
      else
        $element[0].getBoundingClientRect()

    $scope.$on 'destroyed', ->
      console.log "detroyed"
      Nav.go('photos')
  )