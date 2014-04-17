

angular.module( 'Slide', [])
  .factory('Page', (PrefixedStyle, PrefixedEvent)->
    class Page
      constructor: (@id, @parent, @left, @right) ->

        @element = angular.element("<div class='gallery-page'></div>")
        offset = if @left then (if @right then -10000 else 10000) else 0
        @updatePosition(offset)
        @parent.append(@element)

        PrefixedEvent @element, "TransitionEnd", =>
          PrefixedStyle @element[0], 'transition', null

      updatePosition: (offset)->
        @x = offset
        if offset
          PrefixedStyle @element[0], 'transform', "translate3d(#{offset}px, 0, 0)"
        else
          PrefixedStyle @element[0], 'transform', null

      setAnimate: (prop)->
        PrefixedStyle @element[0], 'transition', prop

      content: (slide)->
        @element.empty()
        @element.append slide.element

    Page
  )
  .controller('SlideCtrl', ($scope, $timeout)->
    console.log 'SlideCtrl'
    objects = null
    current = null
    page = null
    ctrl = this
    slideView = null
    Slide = null
    range = 3

    @getCurrentIndex = ()->
      current?.index

    @prev = ->
      if current.left
        slideView.prev()

    @next = ->
      if current.right
        slideView.next()

    @enterBackground = ->
      current.onHide()

    @enterForeground = ->
      current.onShow()

    @setDirection = ->
      if current.left and current.right
        dir = 'both'
      else if current.left
        dir = 'right'
      else if current.right
        dir = 'left'
      else
        dir = 'none'
      slideView.setDirection dir

    @initSlides = (factory, objs, index)->

      #console.log 'initSlides'
      Slide = factory
      slideView = $scope.slideView
      objects = objs
      current = new Slide($scope, objs[index], index)
      page = slideView.getCurrentPage()
      page.content current
      current.onAttach()
      $timeout (=>@onSlide()), 10

    @onSlide = (x)->
      #console.log "onSlide"
      page = slideView.getCurrentPage()
      if x > 0
        #console.log "slide to left"
        current.onHide()

        if ref = current.right
          ref.detach()
        #console.log "remove right", ref.index

        current = current.left
        @loadNeighbors(current)

        if ref = current.left
          page.left.content ref
          ref.onAttach()
        #console.log "prepend", ref.index

      else if x < 0
        #console.log "slide to right"
        current.onHide()
        if ref = current.left
          ref.detach()
        #console.log "remove left", ref.index

        current = current.right
        @loadNeighbors(current)

        if ref = current.right
          page.right.content ref
          ref.onAttach()
        #console.log "append", ref.index

        # Init load, postpone neighbors loading after first slide entered
      else
        @loadNeighbors(current)
        if ref = current.left
          page.left.content ref
          ref.onAttach()
        if ref = current.right
          page.right.content ref
          ref.onAttach()

      current.onShow()
      @setDirection()
      $scope.$emit 'gallery.slide', current.index, x

      # make sure scope digest called
      $timeout ->
        $scope.first = not current.left
        $scope.last = not current.right

    @loadNeighbors = (slide)->
      index = slide.index
      next = slide
      for [1..range]
        if index-- > 0
          if not next.left
            next.left = new Slide($scope, objects[index], index)
            #console.log "add #{index} to left of  #{next.index}"
            next.left.right = next
          next = next.left
        else
          break
      # Remove slide out of range
      next.left = null

      index = slide.index
      next = slide
      for [1..range]
        if ++index < objects.length
          if not next.right
            next.right = new Slide($scope, objects[index], index)
            #console.log "add #{index} to right of  #{next.index}"
            next.right.left = next
          next = next.right
        else
          break
      # Remove slide out of range
      next.right = null

    #slide object may not in DOM
    onResize = ->
      current.onResize()
      next = current
      while next = next.left
        next.onResize()
      next = current
      while next = next.right
        next.onResize()

    window.addEventListener "resize", onResize
    # Avoid memery leak here
    clearOnExit = ->
      #ctrl.pause()
      window.removeEventListener 'resize', onResize

    $scope.$on '$destroy', clearOnExit

    this
  )
  .directive('slideView', (Page, Swipe, PrefixedStyle, PrefixedEvent, $timeout)->
    controller: 'SlideCtrl'
    link: (scope, element, attr, ctrl) ->

      timing = "cubic-bezier(0.645, 0.045, 0.355, 1.000)"
      snaping = false
      swiper = null
      width = 0
      #contruct cycle chained page
      current = new Page(1, element)
      current.right = new Page(2, element, current)
      current.left = new Page(3, element, current.right, current)
      current.right.right = current.left

      PrefixedEvent element, "TransitionEnd", (e)->
        #console.log "slide end"
        if snaping
          snaping = false
          swiper.setDisable false

      animateTo = (direction, ratio)->
        #direction = 0, 1, -1
        #width maybe vary on resize, onStart is not called when next, prev
        #width = element[0].clientWidth  #emulate a onStart, onMove
        offset = direction*width
        #console.log offset, width, ratio
        if ratio
          time = Math.round ratio * 400
          prop = "all #{time}ms #{timing}"
          snaping = true
          swiper.setDisable true
          current.setAnimate(prop)

        if direction <= 0
          current.right.setAnimate(prop) if ratio
          current.right.updatePosition offset+width
        if direction >=0
          current.left.setAnimate(prop) if ratio
          current.left.updatePosition offset-width

        current.updatePosition offset
        if direction isnt 0
          if direction > 0
            current = current.left
          else
            current = current.right
          ctrl.onSlide(direction)

      onStart = (x)->
        #@ctrl.pause()
        #width maybe vary on resize
        width = element[0].clientWidth
        current.setAnimate('none')
        current.left.setAnimate('none')
        current.right.setAnimate('none')
        #console.log "start move", x

      onMove = (offset)->
        current.updatePosition(offset)
        current.right.updatePosition(offset+width) if offset <= 0
        current.left.updatePosition(offset-width) if offset >= 0

      onEnd = (offset, ratio)->
        #console.log "end move", offset, ratio
        if offset > 0
          offset = 1
        else if offset < 0
          offset = -1
        animateTo(offset, ratio)

      swiper = Swipe element,
        onStart: onStart
        onMove: onMove
        onEnd: onEnd
        margin: 100

      scope.slideCtrl = ctrl
      scope.slideView =
        getCurrentPage: -> current
        prev: ->
          onStart()
          onMove(0)
          $timeout (->animateTo(1, 1)), 10
        next: ->
          onStart()
          onMove(0)
          $timeout (->animateTo(-1, 1)), 10
        setDirection: (dir)->
          if dir is 'none'
            swiper.setDisable true
          else
            swiper.setDisable false
            swiper.setDirection dir

  )




