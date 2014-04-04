

angular.module( 'Gallery', [])
  .controller('GalleryCtrl', ($scope, Slide, ImageUtil, $timeout, PrefixedStyle, PrefixedEvent)->

    objects = $scope.objects
    container = current = null
    ctrl = this
    range = 3

    # for Debug use
#    @getCurrent = ()-> current
#    window.ctrl = this

    @setTransform = (el, rect)->
      offsetX = rect.left+rect.width/2-window.innerWidth/2
      offsetY = rect.top+rect.height/2-window.innerHeight/2
      ratioX = rect.width/window.innerWidth
      ratioY = rect.height/window.innerHeight
      PrefixedStyle el, 'transform', "translate3d(#{offsetX}px, #{offsetY}px, 0) scale3d(#{ratioX}, #{ratioY}, 0)"

    @initSlides = (element)->
      index = $scope.index
      container = element
      current = new Slide(this, objects[index], index)
      container.empty()
      container.append(current.element)

    @onSlide = (x)->
      if x > 0
        #console.log "slide to left"
        current.element.removeClass('active')

        if ref = current.right
          #console.log "remove right", ref.index
          # Need to rebind event
          ref.swiper = null
          ref.element.remove()

        current = current.left
        @loadNeighbors(current)

        #if ref = current.left
          #console.log "prepend", ref.index
        container.prepend(current.left.element) if current.left
        $scope.$emit 'gallery.slide', current.index, x

      else if x < 0
        #console.log "slide to right"
        current.element.removeClass('active')
        if ref = current.left
          #console.log "remove left", ref.index
          ref.swiper = null
          ref.element.remove()

        current = current.right
        @loadNeighbors(current)

        #if current.right
          #console.log "append", current.right.index
        container.append(current.right.element) if current.right
        $scope.$emit 'gallery.slide', current.index, x

      # Init load, postpone neighbors loading after first slide entered
      else
        @loadNeighbors(current)
        container.prepend(current.left.element) if current.left
        container.append(current.right.element) if current.right

      current.bindSwipe()
      current.element.addClass('active')

      # make sure scope digest called
      $timeout ->
        $scope.first = not current.left
        $scope.last = not current.right

      #debug info
#      info = "current: " + current.index + " left: "
#      next = current
#      while next = next.left
#        info += " #{next.index} "
#      info += "right: "
#      next = current
#      while next = next.right
#        info += " #{next.index} "
#      console.log info

    @loadNeighbors = (slide)->
      index = slide.index
      next = slide
      for [1..range]
        if index-- > 0
          if not next.left
            next.left = new Slide(this, objects[index], index, 'left')
            #console.log "add #{index} to left of  #{next.index}"
            next.left.right = next
          next = next.left
        else
          break
      # Remove slide out of range
      delete next.left if next.left

      index = slide.index
      next = slide
      for [1..range]
        if ++index < objects.length
          if not next.right
            next.right = new Slide(this, objects[index], index, 'right')
            #console.log "add #{index} to right of  #{next.index}"
            next.right.left = next
          next = next.right
        else
          break
      # Remove slide out of range
      delete next.right if next.right

    auto = null
    @play = ->
      auto = setInterval (->current.next()), 3000
      $scope.playing = true
    @pause = ->
      clearInterval(auto) if auto
      auto = null
      $scope.playing = false

    # Avoid memery leak here
    clearOnExit = ->
      ctrl.pause()

    $scope.$on '$destroy', clearOnExit

    @close = ->
      $scope.displayCtrl = no
      PrefixedStyle container[0], 'transition', 'all ease-in 300ms'
      ctrl.setTransform container[0], $scope.getItemRect()
      PrefixedEvent container, "TransitionEnd", ->
        $scope.$emit 'destroyed'

    $scope.onCtrl = (e, id)->
      switch id
        when 'info'
          ctrl.pause()
          $scope.onImageInfo(current.index)
        when 'close' then ctrl.close()
        when 'prev' then current.prev()
        when 'next' then current.next()
        when 'slide' then $scope.displayCtrl = not $scope.displayCtrl
        when 'play' then (if auto then ctrl.pause() else ctrl.play())
      e.stopPropagation()

    this
  )
  .factory('Slide', (Swipe, PrefixedStyle, PrefixedEvent, ImageUtil)->

    createImage = (url)->
      img = new Image()
      img.src = url
      img.draggable = false
      img.className = "gallery-img"
      img

    timing = "cubic-bezier(0.645, 0.045, 0.355, 1.000)"
    protoElement = angular.element '<div class="gallery-slide"></div>'

    createLoader = (data)->
      url = ImageUtil.thumb(data)
      loader = angular.element """
                       <div class='gallery-loader'>
                         <img src='#{url}' draggable='false' width='100%' height='100%'>
                         <div class='gallery-loader-spin'><i class="icon ion-loading-a"></i></div>
                       </div>
                       """
      w = data.width
      h = data.height
      rx = window.innerWidth/w
      ry = window.innerHeight/h
      if rx < 1 or ry < 1
        r = Math.min(rx, ry)
        w = r*w
        h = r*h
      loader.css
        width: w+'px'
        height: h+'px'
      loader

    Slide = (ctrl, data, index, position)->

      #console.log "new slide", index, position
      @width = null
      @ctrl = ctrl
      @data = data
      @index = index
      @element = protoElement.clone()

      if position is 'right'
        PrefixedStyle @element[0], 'transform', "translate3d(100%, 0, 0)"
      else if position is 'left'
        PrefixedStyle @element[0], 'transform', "translate3d(-100%, 0, 0)"

      loader = createLoader(data)
      @element.append loader
      @img = createImage ImageUtil.best(data)
      @img.onload = =>
        loader.remove()
        @element.append @img
        #@element.removeClass('gallery-loading')
        #console.log "image load", @img.src
      @img.onerror = =>
        #loader.remove()
        #@element.removeClass('gallery-loading')
        loader.addClass('gallery-error')
        #console.log "image error", @img.src
      this

    Slide::bindSwipe = ()->

      #Already bind
      if @swiper
        #console.log "enable swipe of #{@index}"
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

      #console.log "bind swipe of #{@index}, on #{direction}"
      PrefixedEvent @element, "TransitionEnd", =>
        if @snaping
          @snaping = false
          @resetState()

      options =
        direction: direction
        margin: 100
        onStart: (x)=>
          @width = @element[0].offsetWidth
          @setAnimate('none')
          @ctrl.pause()
          @left.setAnimate('none') if @left
          @right.setAnimate('none') if @right

        onMove: (offset)=>
          @updatePosition(offset)
          @right.updatePosition(offset+@width) if @right and offset < 0
          @left.updatePosition(offset-@width) if @left and offset > 0

        onEnd: (offset, aniRatio)=>
          if aniRatio
            @snaping = true
            #console.log "disable swipe of #{@index}"
            @swiper.setDisable true
            time = aniRatio * 0.4
            prop = "all #{time}s #{timing}"
            if offset > 0
              offset = 1
            else if offset < 0
              offset = -1
            @animateTo(offset, prop)
          else
            @resetState()

      @swiper = Swipe @element, options

    Slide::animateTo = (direction, prop="all 0.4s #{timing}")->
      #direction = 0, 1, -1
      @snaping = true
      offset = direction*@width
      @setAnimate prop
      if direction <= 0 and @right
        @right.setAnimate prop
        @right.updatePosition offset+@width
      if direction >=0 and @left
        @left.setAnimate prop
        @left.updatePosition offset-@width

      @updatePosition offset
      if direction isnt 0
        @ctrl.onSlide(direction)


    Slide::next = (prop="all 0.4s #{timing}")->
      if @right
        @width = @element[0].offsetWidth
        @animateTo(-1)

    Slide::prev = (prop="all 0.4s #{timing}")->
      if @left
        @width = @element[0].offsetWidth
        @animateTo(1)

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
        #console.log "enable swipe of #{@index}"
        @swiper.setDisable false
        @updatePosition 0

    Slide

  )
  .directive('galleryView', (PrefixedStyle)->
    restrict: 'E'
    replace: true
    controller: 'GalleryCtrl'
    templateUrl: 'modal/gallery.tpl.html'
    link: (scope, element, attr, ctrl) ->

      slides = element[0].firstElementChild
      ctrl.setTransform slides, scope.rect
      ctrl.initSlides(angular.element(slides))

      element.ready ->
        PrefixedStyle slides, 'transition', 'all ease-in 300ms'
        PrefixedStyle slides, 'transform', null
        ctrl.onSlide()
  )



