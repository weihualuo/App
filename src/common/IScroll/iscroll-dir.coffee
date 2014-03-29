
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
      ready = false

      updatePosition = (pos)->
        if pos != null
          y = -((40-pos)/2).toFixed(2)
          ratio = (pos/40).toFixed(1)
          console.log ratio, y
          PrefixedStyle raw, 'transform', "translate3d(0, #{y}px, 0) scale3d(#{ratio}, #{ratio}, 0)"
        else
          console.log 'clear'
          PrefixedStyle raw, 'transform', null

      setAnimate = (prop)->
        PrefixedStyle raw, 'animation', prop

      height = 40
      scroll.on 'scroll', ->
        if 0 < @y <= height
          ready = false
          updatePosition @y
        if @y > height
          ready = true
          scroll.scrollTo(0, 40)

      scroll.on 'scrollEnd', ->
        console.log "scrollEnd", @y
        updatePosition null
        if ready
          setAnimate('shrinking 1s linear 0 infinite')


  )