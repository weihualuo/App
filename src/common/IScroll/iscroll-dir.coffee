
angular.module( 'Iscroll', [])
  .directive('content', ($timeout, $compile)->
    restrict: 'E'
    replace: true
    transclude: true
#    scope: {},
    template: """
              <div class="fill">
                <div class="scroll clearfix" ng-transclude></div>
              </div>
              """
    link: (scope, element, attr)->

      scroll = null
      options =
        mouseWheel: true
        probeType: 2
      element.ready ->
        dom = element[0]
        window.scroll = scroll = new IScroll dom, options
        scope.$iscroll = scroll

        refresher = $compile('<refresher></refresher>')(scope)
        dom.insertBefore(refresher[0], dom.children[0])

      scope.$on 'scroll.resize', ->
        console.log "scroll.resize"
        $timeout (->scroll.refresh()), 500
  )
  .directive('refresher', (PrefixedStyle)->
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
      updatePosition = (pos)->
        if pos != null
          y = -((height-pos)/2).toFixed(2)
          ratio = (pos/height).toFixed(1)
          console.log ratio, y
          PrefixedStyle raw, 'transform', "translate3d(0, #{y}px, 0) scale3d(#{ratio}, #{ratio}, 0)"
        else
          console.log 'clear'
          PrefixedStyle raw, 'transform', null

      setAnimate = (prop)->
        PrefixedStyle raw, 'animation', prop

      updatePosition(0)

      scroll.on 'scroll', ->
        if 0 < @y <= height
          updatePosition @y
          if state is 1
            state = 0
            @offset = 0

        if @y > height
          if state is 0
            state = 1
            @offset = height

      scroll.on 'scrollEnd', ->
        console.log "scrollEnd", state
        updatePosition null
        if state is 1
          state = 2
          setAnimate('shrinking 1s linear 0 infinite')
          scope.$emit 'refreshStart'

      scope.$on 'scroll.refreshComplete', ->
        console.log "scroll.refreshComplete"
        if state is 2
          setAnimate(null)
          state = 0
          scroll.offset = 0

  )