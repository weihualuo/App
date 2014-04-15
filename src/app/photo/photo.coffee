
angular.module('app.photo', ['NewGallery', 'Slide'])
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
          PrefixedStyle raw, 'transition', 'all 300ms ease-in'
          PrefixedStyle raw, 'transform', null

      scope.$on 'slide.close', (e, index)->
        if scope.scrollView
          PrefixedStyle raw, 'transition', 'all ease-in 300ms'
          setTransform raw, scope.scrollView.getItemRect(index)
          PrefixedEvent element, "TransitionEnd", ->
            console.log "end"
            PrefixedStyle raw, 'transition', null
            scope.$emit 'rect.destroyed'
        else
          scope.$emit 'rect.destroyed'

  )
  .controller( 'PhotoDetailCtrl', ($scope, $controller, $element, $timeout, Nav, Env, Service, TogglePane, ImageSlide)->
    #extend from ListCtrl
    $controller('ListCtrl', {$scope:$scope, name: 'photos'})
    angular.extend($scope, Nav.data())
    $scope.index ?= 0
    if listScope = $scope.listScope
      $scope.scrollView = listScope.scrollView

    env = Env.photoDetail
    env.noHeader = false
    env.noSide = false
    $timeout (->
      env.noHeader = true
      env.noSide = true
      $scope.$emit('envUpdate')
    ), 1000
    $scope.$on 'slide.close', ->
      env.noHeader = false
      env.noSide = false
      $scope.$emit('envUpdate')

    $scope.$on 'rect.destroyed', ->
      Nav.go('photos')

    slideCtrl = null
    $scope.$on 'scroll.reload', ->
      slideCtrl = $scope.slideCtrl
      slideCtrl.initSlides(ImageSlide, $scope.objects, $scope.index)


    onImageInfo = (index)->
      TogglePane
        id: 'infoView'
        template: "<side-pane position='left' class='pane-image-info popup-in-left'></side-pane>"
        url: "modal/imageInfo.tpl.html"
        hash: 'info'
        locals:
          image: $scope.objects[index]

    $scope.onCtrl = (e, id)->

      e.stopPropagation()
      if not Service.noRepeat('slideCtrl', 600)
        return

      switch id
        when 'info'
          #ctrl.pause()
          onImageInfo(slideCtrl.getCurrentIndex())
        when 'close'
          $scope.displayCtrl = no
          $scope.$emit 'slide.close', slideCtrl.getCurrentIndex()
        when 'prev'
          slideCtrl.prev()
        when 'next'
          slideCtrl.next()
        when 'slide'
          $scope.displayCtrl = not $scope.displayCtrl
          $scope.$broadcast('slide.click')

  )