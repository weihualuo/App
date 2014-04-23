

angular.module( 'Widget', [])
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
  .directive('sidePane', (Swipe, PrefixedStyle, PrefixedEvent)->
    restrict: 'E'
    replace: true
    transclude: true
    template:  """
               <div class="side-pane" ng-transclude></div>
               """
    link: (scope, element, attr) ->

      x = 0
      snaping = false
      pane = element[0]

      PrefixedEvent element, "TransitionEnd", ->
        if snaping
          snaping = false
          resetState()

      updatePosition = (offset)->
        x = offset
        if offset
          PrefixedStyle pane, 'transform', "translate3d(#{offset}px, 0, 0)"
        else
          PrefixedStyle pane, 'transform', null

      setAnimate = (prop)->
        PrefixedStyle pane, 'transition', prop

      resetState = ()->
        if x is 0
          setAnimate(null)
        else
          setAnimate('none')
          scope.$emit 'content.closed'

      options =
        direction: attr.position
        onStart: ->
          setAnimate('none')
        onMove: (offset)->
          updatePosition offset
        onEnd: (offset, ratio)->
          if ratio
            snaping = true
            time = Math.round(ratio * 300)
            setAnimate "all #{time}ms ease-in"
            updatePosition offset
          else
            updatePosition offset
            resetState()

      element.ready ->
        Swipe element, options

  )
  .directive('navable', ($compile, $animate, $http, $templateCache)->

    link:(scope, element, attr)->

      stack = []
      container = angular.element "<div style='position: absolute; width:100%'></div>"
      if ani = attr.animation
        container.addClass(ani)

      getContent = (url)->
        template = $templateCache.get(url)
        content = container.clone().html(template)
        $compile(content)(scope)

      current = getContent scope.$eval(attr.navable)
      element.empty()
      element.append(current)
      element.ready ->
        height = current[0].offsetHeight
        #At present: only set the height to first view,
        #the other view maybe hide if hight than first view
        #In that case, to update the diretive
        element.css
          height: height+'px'

      scope.navCtrl =
        go: (url)->
          child = getContent url
          stack.push current
          $animate.addClass(current, 'stacked')
          $animate.enter(child, element)
          current = child
          null
        back: ->
          if stack.length
            $animate.leave(current)
            current = stack.pop()
            $animate.removeClass(current, 'stacked')
          null
  )




