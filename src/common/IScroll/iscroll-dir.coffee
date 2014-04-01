
angular.module( 'Scroll', [])
  .directive('scrollable', ($timeout, $compile)->
    (scope, element, attr)->
      scroll = null
      element.ready ->
        raw = element[0]
        scrollable = attr.scrollable
        options =
          scrollingX: scrollable is 'true' or scrollable is 'x'
          scrollingY: scrollable isnt 'x'
          paging: attr.paging?
          bouncing: not attr.paging?

        scope.$scroll = scroll = new EasyScroller raw, options

        if attr.refreshable? and attr.refreshable != 'false'
          refresher = $compile('<refresher></refresher>')(scope)
          raw.parentNode.insertBefore(refresher[0], raw)

      scope.$on 'scroll.reload', ->
        if scroll
          scroll.scroller.scrollTo(0, 0)
          $timeout (->scroll.reflow()), 1000

  )
  .directive('refresher', ($timeout, PrefixedStyle)->
    restrict: 'E'
    replace: true
    template: """
              <svg class="refresher">
                <circle cx="25" cy="25" r="15" fill="blue"/>
              </svg>
              """
    link: (scope, element, attr)->

      position = 0
      height = 50
      updatePosition = (pos)->
        if pos != null
          position = pos
          y = -((height-pos)/2).toFixed(2)
          ratio = (pos/height).toFixed(2)
          PrefixedStyle raw, 'transform', "translate3d(0, #{y}px, 0) scale3d(#{ratio}, #{ratio}, 0)"
        else
          PrefixedStyle raw, 'transform', null

      setAnimate = (prop)->
        PrefixedStyle raw, 'animation', prop

      raw = element[0]
      scroll = scope.$scroll
      scroller = scroll.scroller
      enableMore = true
      scroll.onScroll (left, top)->
        if top >= 0
          if enableMore
            max = scroller.getScrollMax().top
            if top-5 > max > 0
              enableMore = false
              scope.$emit 'scroll.moreStart'

        else if top >= -height
          updatePosition(-top)
        else if position != height
          updatePosition height

      scroller.activatePullToRefresh height, (->), (->), ->
        setAnimate('shrinking 0.5s linear 0 infinite alternate')
        scope.$emit 'scroll.refreshStart'

      scope.$on 'scroll.refreshComplete', ->
        $timeout (->
          scroller.finishPullToRefresh()
          setAnimate(null)
          scroll.reflow()
        ), 1000

      scope.$on 'scroll.moreComplete', (e, more)->
        $timeout (->
          enableMore = more
          scroll.reflow()
        ), 1000

      scope.$on 'scroll.reload', ->
        enableMore = true

      updatePosition(0)

  )