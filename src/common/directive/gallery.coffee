

angular.module( 'Gallery', [])
  .controller('GalleryCtrl', ($scope, $filter)->

    slides = []
    @addImage = (img)->
      slides.push img

    @initSlides = ->
      current = Math.floor slides.length/2
      if $scope.index < current
        start = 0
        current = $scope.index
      else
        start = $scope.index - current

      console.log start, current
      for img in slides
        img.src = $filter('fullImagePath')($scope.objects[start++], 0)
      current

    this
  )
  .directive('galleryView', ($timeout)->
    restrict: 'E'
    replace: true
    transclude: true
    controller: 'GalleryCtrl'
    template: """
              <div class="gallery-view fade-in-out" ng-click="onClick($event)">
                <div scrollable='x' paging=5 class="gallery-slides">
                </div>
              </div>
              """
    link: (scope, element, attr, ctrl) ->

      scope.onClick = (e)->
        e.stopPropagation()
        scope.$emit 'destroyed'

  )
  .directive('gallerySlides', ()->
    restrict: 'C'
    require: '^galleryView'

    compile: (element, attr)->

      slide = angular.element '<div class="gallery-slide"></div>'
      num = parseInt(attr.paging) or 5
      ratio = 100/num
      element.css width: "#{num}00%"
      slide.css width: "#{ratio}%"
      for [1..num]
        element.append(slide.clone())

      (scope, element, attr, ctrl) ->

        scroll = null
        element.ready ->
          scroll = scope.$scroll
          current = ctrl.initSlides()
          scroll.toPage(current)

  )
  .directive('gallerySlide', ()->
    restrict: 'C'
    require: '^galleryView'
    link: (scope, element, attr, ctrl) ->
      img = new Image()
      img.draggable = false
      img.className = "gallery-img"
      element.append(img)
      ctrl.addImage img

  )

