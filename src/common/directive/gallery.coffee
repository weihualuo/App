

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
      #console.log "shift to #{page}, before shift startindex is #{start}"
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
      $scope.index = start + current
      $scope.$digest()

    ctrl = this
    $scope.onScrollEnd = ->
      page = scroll.getPage()
      if page is parseInt(page) and page isnt current
        ctrl.shiftSlides(page)

    auto = null
    play = ->
      auto = setInterval (->scroll.next()), 3000
      $scope.playing = true
    pause = ->
      clearInterval(auto) if auto
      auto = null
      $scope.playing = false

    $scope.onCtrl = (e, id)->
      switch id
        when 'info'
          pause()
          $scope.onImageInfo($scope.index)
        when 'close'
          pause()
          $scope.$emit 'destroyed'

        when 'prev' then scroll.prev()
        when 'next' then scroll.next()
        when 'slide' then $scope.hideCtrl = !$scope.hideCtrl
        when 'play' then (if auto then pause() else play())
      e.stopPropagation()

    this
  )
  .directive('galleryView', ($timeout)->
    restrict: 'E'
    replace: true
    transclude: true
    controller: 'GalleryCtrl'
    template: """
              <div class="gallery-view fade-in-out" ng-click="onCtrl($event, 'slide')">
                <div scrollable='x' complete="onScrollEnd()" paging=5 class="gallery-slides"></div>
                <div class="gallery-controls" ng-class="{'ng-hide':hideCtrl}" ng-transclude></div>
              </div>
              """
    link: (scope, element, attr, ctrl) ->

      element.ready ->
        ctrl.initSlides()

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

