
angular.module( 'Scroll', [])
  .directive('scrollable', ($timeout, $compile)->
    (scope, element, attr)->
      scroll = null
      raw = element[0]
      scrollable = attr.scrollable
      complete = if attr.complete then (->scope.$eval(attr.complete)) else angular.noop
      options =
        scrollingX: scrollable is 'true' or scrollable is 'x'
        scrollingY: scrollable isnt 'x'
        paging: attr.paging?
        bouncing: not attr.paging?
        scrollingComplete: complete

      scope.$scroll = scroll = new EasyScroller raw, options

      if attr.refreshable? and attr.refreshable != 'false'
        refresher = $compile('<refresher></refresher>')(scope)
        raw.parentNode.insertBefore(refresher[0], raw)

      #Shoud reflow on element ready
      #Not everyone send a scroll.reload
      element.ready ->
        scroll.reflow()

#      scope.$on 'scroll.reload', ->
#        if scroll
#          scroll.scroller.scrollTo(0, 0)
#          $timeout (->scroll.reflow()), 900
      scope.$on 'list.rendered', ->
        if scroll
          scroll.scroller.scrollTo(0, 0)
          $timeout (->scroll.reflow())

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

      position = lastTop = 0
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
       #console.log scroll.step
      scroller = scroll.scroller
      enableRefersh = false
      enableMore = false
      scroll.onScroll (left, top)->
        if top >= 0
          if enableMore
            max = scroller.getScrollMax().top
            if top+200 > max > 0
              enableMore = false
              scope.$emit 'scroll.moreStart'
          scroll.onStep?(top)
        else if enableRefersh
          if top >= -height
            updatePosition(-top)
          else if position != height
            updatePosition height
        null

      scroller.activatePullToRefresh height, (->), (->), ->
        if enableRefersh
          setAnimate('shrinking 0.5s linear 0 infinite alternate')
          scope.$emit 'scroll.refreshStart'

      scope.$on 'scroll.refreshComplete', ->
        $timeout (->
          scroller.finishPullToRefresh()
          setAnimate(null)
          scroll.reflow()
        ), 1000

      scope.$on 'scroll.moreComplete', (e, more)->
        enableMore = more

      scope.$on 'scroll.reload', ->
        enableRefersh = false
        enableMore = false
        console.log "reload disable"

      scope.$on 'list.rendered', ->
        enableRefersh = true
        enableMore = true
        console.log "rendered enable"

      updatePosition(0)

  )
  .directive('dynamic', ($timeout)->
    (scope, element)->

      scroll = scope.$scroll
      n = 5
      start = end = lastTop =  0
      step = 200

      notify = (newStart, newEnd)->
        #add = remove = []
        children = element.children()
        length = children.length
        if newStart > start
          #remove = remove.concat [start..(newStart-1)]
          for i in [start..(newStart-1)]
            if i >= length then break
            angular.element(children[i]).triggerHandler 'dynamic.remove'
        else if newStart < start
          #add = add.concat [newStart..(start-1)]
          for i in [newStart..(start-1)]
            if i >= length then break
            angular.element(children[i]).triggerHandler 'dynamic.add'
        if newEnd < end
          #remove = remove.concat [newEnd..(end-1)]
          for i in [newEnd..(end-1)]
            if i >= length then break
            angular.element(children[i]).triggerHandler 'dynamic.remove'
        else if newEnd > end
          #add = add.concat [end..(newEnd-1)]
          for i in [end..(newEnd-1)]
            if i >= length then break
            angular.element(children[i]).triggerHandler 'dynamic.add'

        start = newStart
        end = newEnd
         #console.log "remove", remove
         #console.log "add", add
#        children = element.children()
#        length = children.length
#        for i in remove
#          if i >= length then break
#          angular.element(children[i]).triggerHandler 'dynamic.remove'
#        for i in add
#          if i >= length then break
#          angular.element(children[i]).triggerHandler 'dynamic.add'

      update = ->
        item = element[0].firstElementChild

        if not item then return
        top = scroll.scroller.getValues().top
        itemHeight = item.offsetHeight
        containerHeight = element[0].parentNode.clientHeight
        numPerRow = Math.round element[0].clientWidth/item.offsetWidth

         #console.log "top: #{top}, itemHeight: #{itemHeight}, containerHeight: #{containerHeight}, numPerRow: #{numPerRow}"

        # row above fully invisible
        rowHide = Math.floor top/itemHeight
        if rowHide > n
          newStart = (rowHide-n)*numPerRow
        else
          newStart = 0

        # lastRow visible
        bottomRow = Math.ceil (top+containerHeight)/itemHeight
        newEnd = (bottomRow+n)*numPerRow

         #console.log "rowHide: #{rowHide}, bottomRow: #{bottomRow}, newStart is #{newStart}, newEnd is #{newEnd}"
         #console.log "Items keep: #{newEnd-newStart}, row: #{(newEnd-newStart)/numPerRow}"
        notify(newStart, newEnd)
        lastTop = top

      scroll.onStep = (top)->
        if Math.abs(top-lastTop) > step
          #console.log "onStep", top
          update()

#      scope.$on 'scroll.reload', ->
#        start = end = lastTop =  0
#        $timeout update, 1000

      scope.$on 'list.rendered', ->
        start = end = lastTop =  0
        $timeout update
  )