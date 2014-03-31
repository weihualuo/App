
angular.module( 'Scroll', [])
  .directive('scrollable', ($timeout, $compile)->
    (scope, element, attr)->
      scroll = null
      element.ready ->
        raw = element[0]
        options =
          scrollingX: false
        scroll = new EasyScroller raw, options
        scope.$scroll = scroll
        if attr.refreshable? and attr.refreshable != 'false'
          refresher = $compile('<refresher></refresher>')(scope)
          raw.parentNode.insertBefore(refresher[0], raw)

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

      position = 0
      height = 40
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
      scroll.onScroll (left, top)->
        if top >= 0 then return
        if top >= -height
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
        ), 1000

      updatePosition(0)

  )