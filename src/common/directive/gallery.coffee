

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
  .factory('Slide', (Swipe, PrefixedStyle)->

    CreateImage = (url)->
      img = new Image()
      img.src = url
      img.draggable = false
      img.className = "gallery-img"
      img

    Slide = (url, position)->

      loader = angular.element '<i class="icon icon-large ion-loading-d"></i>'
      @element = angular.element '<div class="gallery-slide gallery-loading"></div>'
      if position is 'right'
        PrefixedStyle @element[0], 'transform', "translate3d(100%, 0, 0)"
      else if position is 'left'
        PrefixedStyle @element[0], 'transform', "translate3d(-100%, 0, 0)"

      @element.append loader
      @img = CreateImage(url)
      @img.onload = =>
        loader.remove()
        @element.append @img
        @element.removeClass('gallery-loading')
        console.log "image load", url
      @img.onerror = =>
        loader.remove()
        @element.removeClass('gallery-loading')
        @element.addClass('gallery-error')
        console.log "image error", url

      options =
        onStart: -> console.log "start"
        onMove: (offset)-> console.log offset
        onEnd: (offset, ratio)-> console.log offset, ratio
      Swipe @element, options


      this

    Slide.prototype.loadNeighbor = ->
      @left = new Slide()
      @right = new Slide()


    Slide

  )
  .directive('galleryView', ($timeout)->
    restrict: 'E'
    replace: true
    transclude: true
    controller: 'GalleryCtrl'
    template: """
              <div class="gallery-view gallery-controls fade-in-out" ng-click="onCtrl($event, 'slide')">
                <div class="gallery-slides"></div>
                <span class="title">
                {{objects[index].title}}
                </span>
                <span class="prev" ng-click="onCtrl($event, 'prev')">‹</span>
                <span class="next" ng-click="onCtrl($event, 'next')">›</span>
                <span class="close" ng-click="onCtrl($event, 'close')"><i class="icon ion-ios7-close-outline"></i></span>
                <span class="play-pause" ng-click="onCtrl($event, 'play')">
                <i class="icon ion-play" ng-class="{'ng-hide': playing}"></i>
                <i class="icon ion-pause" ng-class="{'ng-hide': !playing}"></i>
                </span>
                <span class="info" ng-click="onCtrl($event, 'info')">
                <i class="icon ion-ios7-information-outline"></i>
                </span>
              </div>
              """
    link: (scope, element, attr, ctrl) ->

  )
  .directive('gallerySlides', (Slide, ImageUtil)->
    restrict: 'C'
    require: '^galleryView'
    link: (scope, element, attr, ctrl) ->
      objects = scope.objects
      index = scope.index
      url = ImageUtil.path(objects[index], 0)
      slide = new Slide(url)

      if index > 0
        url = ImageUtil.path(objects[index-1], 0)
        slide.left = new Slide(url, 'left')

      if index + 1 < objects.length
        url = ImageUtil.path(objects[index+1], 0)
        slide.right = new Slide(url, 'right')

      element.append(slide.left.element)
      element.append(slide.element)
      element.append(slide.right.element)

  )
  .directive('xgallerySlide', ()->
    restrict: 'A'
    require: '^galleryView'
    link: (scope, element, attr, ctrl) ->
      img = new Image()
      img.draggable = false
      img.className = "gallery-img"
      element.append(img)
      ctrl.addImage img

  )

