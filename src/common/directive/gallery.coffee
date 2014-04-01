

angular.module( 'Gallery', [])
  .controller('GalleryCtrl', ($scope, $filter)->

    start = mid = current = 0
    slides = []
    scroll = null

    @addImage = (img)->
      slides.push img

    @initSlides = ->
      scroll = $scope.$scroll

      mid = current = Math.floor slides.length/2
      if $scope.index < current
        current = $scope.index
      else
        start = $scope.index - current

      index = start
      for img in slides
        img.src = $filter('fullImagePath')($scope.objects[index++], 0)

      scroll.toPage(current)

    #TODO avoid reflow twice
    @shiftSlides = (page)->
      #console.log "before shift page startindex is ", start
      #case 1: 1+1>=2, need shift, case 2: 0+2>=2, do not need
      if page isnt mid and start + page >= mid
        start += page - mid
        current = mid
        index = start
        for img in slides
          img.src = $filter('fullImagePath')($scope.objects[index++], 0)
        scroll.toPage(current)
        #console.log "after shift page startindex is #{start}, set page from #{page} to #{current}"
      else
        current = page

    ctrl = this
    $scope.onScrollEnd = ->
      page = scroll.getPage()
      if page is parseInt(page) and page isnt current
        ctrl.shiftSlides(page)

    this
  )
  .directive('galleryView', ($timeout)->
    restrict: 'E'
    replace: true
    transclude: true
    controller: 'GalleryCtrl'
    template: """
              <div class="gallery-view fade-in-out" ng-click="onClick($event)">
                <div scrollable='x' complete="onScrollEnd()" paging=5 class="gallery-slides">
                </div>
              </div>
              """
    link: (scope, element, attr, ctrl) ->

      element.ready ->
        ctrl.initSlides()

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

