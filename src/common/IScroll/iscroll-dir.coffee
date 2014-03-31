
angular.module( 'Iscroll', [])
  .directive('scrollable', ($timeout, $compile)->
    (scope, element, attr)->
      scroll = null
      element.ready ->
        options =
          scrollingX: false
        window.scroll = scroll = new EasyScroller element[0], options

      scope.$on 'scroll.resize', ->
        console.log "scroll.resize"
        $timeout (->scroll.reflow()), 1000

  )
  .directive('content', ($timeout, $compile)->
    restrict: 'E'
    replace: true
    transclude: true
    template: """
              <div class="fill">
                <div class="scroll clearfix" ng-transclude></div>
              </div>
              """
    link: (scope, element, attr)->

      scroll = null

      element.ready ->

        dom = element[0]
        options =
          scrollingX: false

        window.scroll = scroll = new EasyScroller dom.firstElementChild, options
        scope.$iscroll = scroll

        if attr.refresh? and attr.refresh != 'false'
          refresher = $compile('<refresher></refresher>')(scope)
          dom.insertBefore(refresher[0], dom.children[0])

      scope.$on 'scroll.resize', ->
        console.log "scroll.resize"
        $timeout (->scroll.reflow()), 1000
  )
  .directive('refresher', ($timeout, PrefixedStyle)->
    restrict: 'E'
    replace: true
    template: """
              <svg class="refresher">
                <circle cx="20" cy="20" r="15" fill="blue"/>
              </svg>
              """
    link: (scope, element, attr)->

      raw = element[0]
      scroll = scope.$iscroll
      #0: init, 1: ready , 2: refreshing
      state = 0
      height = 40
      position = 0
      updatePosition = (pos)->
        if pos != null
          position = pos
          y = -((height-pos)/2).toFixed(2)
          ratio = (pos/height).toFixed(1)
          PrefixedStyle raw, 'transform', "translate3d(0, #{y}px, 0) scale3d(#{ratio}, #{ratio}, 0)"
        else
          PrefixedStyle raw, 'transform', null

      setAnimate = (prop)->
        PrefixedStyle raw, 'animation', prop

#      updatePosition(0)
      scroll.on = ->

      scroll.on 'beforeScrollStart', ->
        console.log "beforeScrollStart"
      scroll.on 'scrollStart', ->
        console.log "scrollStart"

      scroll.on 'scroll', ->
        if @y <= 0 then return
        if @y <= height
          updatePosition(@y)
          if state is 1
            state = 0
            @offset = 0
        else
          if position is not height
            updatePosition(height)
          if state is 0
            state = 1
            @offset = height

      scroll.on 'scrollEnd', ->
        if position is 0 then return
        if state is 1
          state = 2
          setAnimate('shrinking 0.5s linear 0 infinite alternate')
          scope.$emit 'scroll.refreshStart'
        else
          updatePosition 0

      scope.$on 'scroll.refreshComplete', ->
        if state is 2
          $timeout (->
            setAnimate(null)
            scroll.refresh(true)
            updatePosition(0)
            state = 0
            scroll.offset = 0
            scroll.resetPosition(scroll.options.bounceTime)
          ), 1500

  )