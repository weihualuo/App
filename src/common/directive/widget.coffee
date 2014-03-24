

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
  .directive('verticalEqual', ()->
    (scope, element) ->
      element.ready ->
        raw = element[0]
        height = raw.offsetHeight
        num = raw.children.length
        totalOffset = 0
        totalOffset += item.offsetHeight for item in raw.children
        margin = (height - totalOffset)/(num+1)
        style = marginTop:margin+'px', marginBottom: margin+'px'
        angular.extend item.style, style for item in raw.children

  )
  .directive('sidePane', ($swipe)->
    restrict: 'E'
    replace: true
    transclude: true
    template:  """
               <div class="side-pane" ng-transclude></div>
               """
    link: (scope, element, attr) ->
      
      position = attr.position

      startX = 0
      x = 0
      pane = element[0]

      updatePosition = ->
        pane.style["-webkit-transform"] = "translate3d(#{x}px, 0, 0)"
      setAnimate = (prop)->
        pane.style["-webkit-transition"] = prop

      onShiftEnd = ->
        width = pane.offsetWidth
        if Math.abs(x)*2 > width
          scope.$close()
        else
          x = 0
          updatePosition()

      $swipe.bind element,
        'start': (coords, event)->
          startX = coords.x - x
          setAnimate "none"
          event.stopPropagation()

        'cancel': ->
          onShiftEnd()

        'move': (coords, event)->
          event.stopPropagation()
          x = coords.x - startX
          if (position == 'left' and x > 0) or (position == 'right' and x < 0)
            x = 0
          else
            updatePosition()

        'end': ->
          setAnimate "all 0.3s ease-in"
          onShiftEnd()

  )
  .directive('galleryView', ()->
    restrict: 'E'
    replace: true
    transclude: true
    template: '<div class="blueimp-gallery blueimp-gallery-controls fade-in-out" ng-transclude>' +
              '</div>'

    link: (scope, element) ->

      gallery = null
      element.ready ->
        gallery = scope.gallery = blueimp.Gallery scope.links,
          index: scope.index
          container: element[0]
          startSlideshow: true
          onclose: -> scope.$close()

      scope.onInfo = ->
        gallery.pause()
        scope.onImageInfo(gallery.getIndex())
  )



