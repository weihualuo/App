

angular.module( 'myWidget', [])
  .directive('moreItem', ()->
    restrict: 'E'
    replace: true
    transclude: true
    templateUrl: "template/widget/moreItem.html"
    scope:
      onMore: "&"
    link: (scope, el, attr)->

      onFinished = ->
        scope.loading = no

      if attr.loading is "true"
        setTimeout -> el[0].click()

      el.on 'click', ->
        if !scope.loading
          scope.loading = yes
          scope.onMore onFinished: onFinished
          scope.$apply()

  )
  .directive('myTabs', ()->
    restrict: 'E'
    replace: true
    transclude: true
    template: '<a class="tab-item" ng-click="onTap()" ng-transclude></a>'
    scope:
      activeTab: "="
      onClick: "&"
    link: (scope, el, attr)->

      if attr.activeTab
        scope.$watch 'activeTab', (value)->
          if value is attr.value
            el.addClass('active')
          else
            el.removeClass('active')

      scope.onTap = ->
        scope.onClick()
        if attr.activeTab
          scope.activeTab = attr.value
  )
  .directive( 'fileSelect', ->
    restrict: 'E'
    replace: true
    scope:
      imgsrc: "@"
      file: "="
    template: '<div>
                <div class="image-preview">
                  <div ng-show="reading" class="image-loading"><i class="icon icon-large ion-load-a loading-rotate"></i></div>
                  <img ng-hide="reading" ng-src="{{imgsrc}}">
                </div>
                <input type="file"/>
               </div>'

    link: (scope, element) ->

      originSrc = null

      $input = element.find('input')
      $input.on 'change', (e)->

        #Save the origin src
        originSrc ?= scope.imgsrc
        file = e.target.files[0]
        if file and file.type.indexOf('image') >= 0

          reader = new FileReader()
          reader.onload = (e)->
            scope.reading = no
            scope.file = file
            scope.imgsrc = e.target.result
            scope.$apply()
          #read data take a while on mp
          reader.readAsDataURL(file)
          scope.reading = yes
          scope.$apply()
        # Set to origin src in case of no selection
#        else
#          scope.imgsrc = originSrc
#          scope.$apply()


  )
  .directive('inputFile', ->
    restrict: 'E'
    replace: true
    transclude: true
    scope:
      onSelect: '&'
    template: '<label>'+
                '<div ng-transclude></div>'+
                '<input type="file">'+
              '</label>'
    link: (scope, element, attr) ->
      $input = element.find('input')
      $input.attr('multiple', true) if attr.multiple?
      $input.on 'change', (e)->
        for file in e.target.files
          if file and file.type.indexOf('image') >= 0
            scope.onSelect file:file
        scope.$apply()

  )
  .directive('sideMenu', ($ionicGesture, $timeout)->
    restrict: 'E'
    replace: true
    transclude: true
    scope:
      onHide: '&'
    template: '<div class="side-menu-backdrop popup-in-left" ng-click="onHide()">'+
                '<ul class="side-menu" ng-transclude ng-click="$event.stopPropagation()">'+
                '</ul>'+
              '</div>'
    controller: ->
      
      @_isDragging = false
      @dragThresholdX = 10
      
      @setContent = (content)->
        @content = content
        
      @getRatio = ->
        @getAmount() / @content.width
        
      @getAmount = ->
        @content && @content.getTranslateX() || 0

      @shiftAmount = (amount)->
        @content.setTranslateX amount

      @snapToRest = (e)->
        @content.enableAnimation()
        @_isDragging = false
        ratio = @getRatio()

        velocityThreshold = 0.3
        velocityX = e.gesture.velocityX
        direction = e.gesture.direction
        # Going left, more than half, or quickly
        if(direction == 'left' && ratio <= 0 && (ratio <= -0.5 || velocityX > velocityThreshold))
          @content.hide()
        else
          @shiftAmount(0)

      @endDrag = (e)->
        if @._isDragging
          @snapToRest(e)
        @_startX = null
        @_lastX = null
        @_offsetX = null
      
      @handleDrag = (e)->
        if(!@_startX)
          @_startX = e.gesture.touches[0].pageX
          @_lastX = @_startX
        else
          @_lastX = e.gesture.touches[0].pageX
        # Calculate difference from the tap points
        if(!@_isDragging && Math.abs(@_lastX - @_startX) > @dragThresholdX)
          # if the difference is greater than threshold, start dragging using the current
          # point as the starting point
          @_startX = @_lastX
  
          @_isDragging = true
          # Initialize dragging
          @content.disableAnimation()
          @_offsetX = @getAmount()
          
        if @_isDragging
          amount =  @_offsetX + @_lastX - @_startX
          if amount < 0
            @shiftAmount(amount)
          else
            @_startX = @_lastX

      this

    link: (scope, element, attr, ctrl) ->

      isDragging = false
      defaultPrevented = false

      # locate verticall equally
      elMenu = element[0].querySelector('.side-menu')
      element.ready ->
        height = elMenu.offsetHeight
        num = elMenu.children.length
        totalOffset = 0
        totalOffset += item.offsetHeight for item in elMenu.children
        margin = (height - totalOffset)/(num+1)
        style = marginTop:margin+'px', marginBottom: margin+'px'
        angular.extend item.style, style for item in elMenu.children

      ctrl.setContent

        width: elMenu.offsetWidth

        hide: ->
          scope.onHide()
          scope.$apply()

        getTranslateX: ->  scope.translateX or 0

        setTranslateX: ionic.animationFrameThrottle (amount)->
          if amount is 0
            element[0].style[ionic.CSS.TRANSFORM] = 'none'
          else
            element[0].style[ionic.CSS.TRANSFORM] = 'translate3d(' + amount + 'px, 0, 0)'
          $timeout -> scope.translateX = amount

        enableAnimation: ->
          element[0].classList.add('menu-animated')
        disableAnimation: ->
          element[0].classList.remove('menu-animated')

      dragFn = (e)->
        if  defaultPrevented or e.gesture.srcEvent.defaultPrevented
          return
        isDragging = true
        ctrl.handleDrag(e)
        e.gesture.srcEvent.preventDefault()

      dragVertFn = (e)->
        if isDragging
          e.gesture.srcEvent.preventDefault()

      dragReleaseFn = (e)->
        isDragging = false
        if !defaultPrevented
          ctrl.endDrag(e)
        defaultPrevented = false
        
      swipeFn = (e)->
        scope.onHide()
        scope.$apply()

      dragRightGesture = $ionicGesture.on('dragright', dragFn, element)
      dragLeftGesture = $ionicGesture.on('dragleft', dragFn, element)
      dragUpGesture = $ionicGesture.on('dragup', dragVertFn, element)
      dragDownGesture = $ionicGesture.on('dragdown', dragVertFn, element)
      swipeLeftGesture = $ionicGesture.on('swipeleft', swipeFn, element)
      releaseGesture = $ionicGesture.on('release', dragReleaseFn, element)

      scope.$on '$destroy', ->
        $ionicGesture.off(dragLeftGesture, 'dragleft', dragFn)
        $ionicGesture.off(swipeLeftGesture, 'swipeleft', swipeFn)
        $ionicGesture.off(dragRightGesture, 'dragright', dragFn)
        $ionicGesture.off(dragUpGesture, 'dragup', dragFn)
        $ionicGesture.off(dragDownGesture, 'dragdown', dragFn)
        $ionicGesture.off(releaseGesture, 'release', dragReleaseFn)

  )

