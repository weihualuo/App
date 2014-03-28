
angular.module( 'Iscroll', [])
  .directive('content', ($timeout)->
    restrict: 'E'
    replace: true
    transclude: true
#    scope: {},
    template: """
              <div class="scroll-content">
                <div class="scroll clearfix" ng-transclude></div>
              </div>
              """
    link: (scope, element, attr)->

      scroll = null
      options =
        scrollbars: true
        mouseWheel: true
        probeType: 2
      element.ready ->
        window.scroll = scroll = new IScroll element[0], options
        scroll.on 'scroll', ->
          console.log "scroll", @y

      scope.$on 'scroll.resize', ->
        console.log "scroll.resize"
        $timeout (->scroll.refresh()), 500
  )