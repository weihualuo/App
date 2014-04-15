

angular.module( 'NewGallery', [])
  .factory('ImageSlide', (Swipe, PrefixedStyle, PrefixedEvent, ImageUtil, $compile)->

    createImage = (url)->
      img = new Image()
      img.src = url
      img.draggable = false
      img.className = "gallery-img"
      img

    protoElement = angular.element '<div class="gallery-slide"></div>'

    getLoaderDimension = (data)->
      w = data.width
      h = data.height
      ratio = Math.min(window.innerWidth/w, window.innerHeight/h)
      if ratio < 1
        w = ratio*w
        h = ratio*h
      ret =
        width: w+'px'
        height: h+'px'


    createLoader = (data)->
      url = ImageUtil.thumb(data)
      loader = angular.element """
                               <div class='gallery-loader'>
                               <img src='#{url}' onerror='this.style.display="none"' width='100%' height='100%'>
                               <div class='gallery-loader-spin'><i class="icon ion-loading-a"></i></div>
                               </div>
                               """
      loader.css getLoaderDimension(data)
      loader

    Slide = (@scope, @data, @index)->
      #console.log "new slide", index, position
      @width = null
      @element = protoElement.clone()
      @img = createImage ImageUtil.best(data)
      @loader = createLoader(data)
      @element.append @loader
      @img.onload = =>
        @loader.empty()
        @imgLoad = yes
        @element.prepend @img
        @addTags()
      @img.onerror = =>
        @loader.addClass('gallery-error')
      this

    Slide::addTags = ->
      if @imgLoad and @attached
        for tag in @data.tags
          scope = @scope.$new()
          scope.tag = tag
          @loader.append $compile('<image-tag></image-tag>')(scope)

    Slide::attach = (parent)->
      @attached = yes
      @addTags()
      parent.empty()
      parent.append @element

    Slide::detach = ()->
      @attached = no
      @loader.empty() if @imgLoad
      @element.remove()

    Slide::onShow = ()->
      @element.addClass('active')

    Slide::onHide = ()->
      @element.removeClass('active')

    Slide::onResize = ->
      @loader.css getLoaderDimension(@data)

    Slide

  )

  .directive('imageTag', ($compile)->
    restrict: 'E'
    replace: true
    template: """
              <div class="gallery-tag" ng-click="onClick($event)"><i class="icon ion-ios7-pricetag"></i></div>
              """
    link: (scope, element) ->
      tag = scope.tag
      view = null
      element.css left:"#{tag.left}%", top:"#{tag.top}%"
      scope.onClick = (e)->
        e.stopPropagation()
        if not view
          view = $compile('<tag-view></tag-view>')(scope)
          element.parent().append view
        return

      scope.$on 'slide.click', ->
        if view
          view.remove()
          view = null
  )
  .controller('tagController', ($scope, Many, ImageUtil)->

    list = Many('products')

    $scope.title = $scope.tag.title
    $scope.desc = $scope.tag.desc
    $scope.product = product = list.get($scope.tag.product)
    product.$promise.then ->
      $scope.src = ImageUtil.small(product.params[0])
      if not $scope.title then $scope.title = product.title
      if not $scope.desc then $scope.desc = product.desc

  )
  .directive('tagView', ()->
    restrict: 'E'
    replace: true
    controller: 'tagController'
    template: """
              <div class="tag-view">
                <img ng-src="{{src}}">
                <h5 class='title'>{{title}}</h5>
                <p class='desc'>{{desc}}</p>
              </div>
              """
    link: (scope, element, attr) ->

      width = 250
      height = 125
      tag = scope.tag
      element.css
        width: width+'px'
        height: height+'px'
        display: 'none'

      locate = ->
        left = tag.left
        top = tag.top
        right = 100 - left
        bottom = 100 - top
        rect = element[0].parentNode.getBoundingClientRect()

        leftPoint = rect.left + rect.width*left/100
        if leftPoint <= window.innerWidth - width
          left = left + '%'
          right = null
        else if leftPoint >= width
          left = null
          right = right + '%'
        else
          left = (rect.width - width)/2 + 'px'
          right = null

        topPoint = rect.top + rect.height*top/100
        if topPoint <= window.innerHeight - height
          top = top + '%'
          bottom = null
        else if topPoint >= height
          top = null
          bottom = bottom + '%'
        else
          top = (rect.height - height)/2 + 'px'
          bottom = null

        element.css
          left: left
          right: right
          top: top
          bottom: bottom
          display: 'block'


      element.ready locate
      window.addEventListener "resize", locate
      scope.$on '$destroy', ->
        console.log "tagview destroy"
        window.removeEventListener 'resize', locate

  )





