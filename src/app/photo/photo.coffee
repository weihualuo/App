
angular.module('app.photo', ['NewGallery', 'Slide'])

  .controller( 'PhotoDetailCtrl', ($scope, $controller, $element, $timeout, Nav, Env, Service, TogglePane, ImageSlide)->
    #extend from ListCtrl
    angular.extend($scope, Nav.data())
    $scope.index ?= 0
    if $scope.scope
      Service.inheritScope($scope, $scope.scope)
    else
      $scope.listCtrl =  $controller('ListCtrl', {$scope:$scope, name: 'photos'})

    #Set env to hide or show side & header
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
    initSlide = ->
      slideCtrl = $scope.slideCtrl
      slideCtrl.initSlides(ImageSlide, $scope.objects, $scope.index)

    if $scope.objects
      $scope.objects.$promise.then initSlide
    else
      $scope.$on 'scroll.reload', initSlide


    onImageInfo = (index)->
      TogglePane
        id: 'infoView'
        template: "<side-pane position='right' class='pane-image-info popup-in-right'></side-pane>"
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