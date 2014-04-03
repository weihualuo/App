

angular.module( 'Gallery', [])
  .controller('GalleryCtrl', ($scope, Slide, ImageUtil)->

    objects = $scope.objects
    container = current = width = null
    range = 2

    @getCurrent = ()-> current
    window.ctrl = this

    @getUrl = (obj)-> ImageUtil.path(obj, 0)

    @initSlides = (element)->
      index = $scope.index
      container = element
      current = new Slide(this, objects[index], index)
      container.empty()
      container.append(current.element)
      @loadNeighbors(current)
      container.prepend(current.left.element) if current.left
      container.append(current.right.element) if current.right

    @startSlides = (clientWidth)->
      width = clientWidth
      current.bindSwipe(width)

    @onSlide = (x)->
      if x > 0
        console.log "slide to left"
        if ref = current.right
          console.log "remove right", ref.index
          # Need to rebind event
          ref.swiper = null
          ref.element.remove()

        current = current.left
        @loadNeighbors(current)

        if ref = current.left
          console.log "prepend", ref.index
        container.prepend(current.left.element) if current.left

      else
        console.log "slide to right"
        if ref = current.left
          console.log "remove left", ref.index
          ref.swiper = null
          ref.element.remove()

        current = current.right
        @loadNeighbors(current)

        if current.right
          console.log "append", current.right.index
        container.append(current.right.element) if current.right

      current.bindSwipe(width)
      info = "current: " + current.index + " left: "
      next = current
      while next = next.left
        info += " #{next.index} "
      info += "right: "
      next = current
      while next = next.right
        info += " #{next.index} "
      console.log info



    @loadNeighbors = (slide)->
      index = slide.index
      next = slide
      for [1..range]
        if index-- > 0
          if not next.left
            next.left = new Slide(this, objects[index], index, 'left')
            console.log "add #{index} to left of  #{next.index}"
            next.left.right = next
          next = next.left
        else
          break
      index = slide.index
      next = slide
      for [1..range]
        if ++index < objects.length
          if not next.right
            next.right = new Slide(this, objects[index], index, 'right')
            console.log "add #{index} to right of  #{next.index}"
            next.right.left = next
          next = next.right
        else
          break

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
  .factory('Slide', (Swipe, PrefixedStyle, PrefixedEvent)->

    CreateImage = (url)->
      img = new Image()
      img.src = url
      img.draggable = false
      img.className = "gallery-img"
      img

    protoElement = angular.element '<div class="gallery-slide gallery-loading"></div>'
    protoLoader = angular.element '<i class="icon icon-large ion-loading-d"></i>'

    Slide = (ctrl, data, index, position)->

      console.log "new slide", index, position

      @ctrl = ctrl
      @data = data
      @index = index
      @element = protoElement.clone()


      if position is 'right'
        PrefixedStyle @element[0], 'transform', "translate3d(100%, 0, 0)"
      else if position is 'left'
        PrefixedStyle @element[0], 'transform', "translate3d(-100%, 0, 0)"

      loader = protoLoader.clone()
      @element.append loader
      @img = CreateImage ctrl.getUrl(data)
      @img.onload = =>
        loader.remove()
        @element.append @img
        @element.removeClass('gallery-loading')
      @img.onerror = =>
        loader.remove()
        @element.removeClass('gallery-loading')
        @element.addClass('gallery-error')
        console.log "image error", @img.src
      this

    Slide::bindSwipe = (width)->

      #Already bind
      if @swiper
        console.log "enable swipe of #{@index}"
        @swiper.setDisable false
        return

      if @left and @right
        direction = 'both'
      else if @left
        direction = 'right'
      else if @right
        direction = 'left'
      else
        return

      console.log "bind swipe of #{@index}, on #{direction}"

      PrefixedEvent @element, "TransitionEnd", =>
        if @snaping
          @snaping = false
          @resetState()

      options =
        width: width
        direction: direction
        onStart: (x)=>
          @setAnimate('none')
          @left.setAnimate('none') if @left
          @right.setAnimate('none') if @right

        onMove: (offset)=>
          @updatePosition(offset)
          @right.updatePosition(offset+width) if @right
          @left.updatePosition(offset-width) if @left

        onEnd: (offset, aniRatio)=>
          if aniRatio
            @snaping = true
            console.log "disable swipe of #{@index}"
            @swiper.setDisable true
            time = aniRatio * 0.4
            prop = "all #{time}s ease-in"
            @setAnimate prop
            @updatePosition offset
            console.log offset, aniRatio, width
            if @right
              @right.setAnimate prop
              @right.updatePosition(offset+width)
            if @left
              @left.setAnimate prop
              @left.updatePosition(offset-width)
          else
            @resetState()
      @swiper = Swipe @element, options


    Slide::setAnimate = (prop)->
      PrefixedStyle @element[0], 'transition', prop

    Slide::updatePosition = (offset)->
      @x = offset
      if offset
        PrefixedStyle @element[0], 'transform', "translate3d(#{offset}px, 0, 0)"
      else
        PrefixedStyle @element[0], 'transform', null

    Slide::resetState = ->
      @setAnimate(null)
      @left.setAnimate(null) if @left
      @right.setAnimate(null) if @right
      if @x is 0
        console.log "enable swipe of #{@index}"
        @swiper.setDisable false
      else
        @ctrl.onSlide(@x)

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
  )
  .directive('gallerySlides', (Slide, ImageUtil)->
    restrict: 'C'
    require: '^galleryView'
    link: (scope, element, attr, ctrl) ->

      width = null
      ctrl.initSlides(element)

      element.ready ->
        width = element[0].clientWidth
        ctrl.startSlides(width)

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

