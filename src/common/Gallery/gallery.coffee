

angular.module( 'NewGallery', [])
  .controller('GalleryCtrl', ($scope, Slide, $timeout, PrefixedStyle, PrefixedEvent, Service, TogglePane, $compile)->
  )
  .factory('Slide', (Swipe, PrefixedStyle, PrefixedEvent, ImageUtil)->

  )
  .factory('Page', ()->

    protoElement = angular.element '<div class="gallery-slide"></div>'


  )
  .directive('galleryView', (PrefixedStyle)->
    restrict: 'E'
    replace: true
    controller: 'GalleryCtrl'
    templateUrl: 'modal/gallery.tpl.html'
  )
  .factory('Page', (PrefixedStyle)->



    class Page
      constructor: (@id, @parent, @left, @right) ->

        @element = angular.element("<div class='gallery-page'></div>")
        @updatePosition(10000)
        @parent.append(@element)

      onShow: () ->
        @updatePosition(0)

      updatePosition: (offset)->
        @x = offset
        if offset
          PrefixedStyle @element[0], 'transform', "translate3d(#{offset}px, 0, 0)"
        else
          PrefixedStyle @element[0], 'transform', null

      setAnimate: (prop)->
        PrefixedStyle @element[0], 'transition', prop

      animateTo: (direction, prop="all 0.4s #{timing}")->
        #direction = 0, 1, -1
        @snaping = true
        offset = direction*@width
        @setAnimate prop
        if direction <= 0 and @right
          @right.setAnimate prop
          @right.updatePosition offset+@width
        if direction >=0 and @left
          @left.setAnimate prop
          @left.updatePosition offset-@width

        @updatePosition offset
        if direction isnt 0
          @ctrl.onSlide(direction)

    Page
  )
  .directive('gallerySlides', (Page, Swipe)->
    restrict: 'C'
    link: (scope, element, attr, ctrl) ->
      #contruct cycle chained page
      current = new Page(1, element)
      current.right = new Page(2, element, current)
      current.left = new Page(3, element, current.right, current)
      current.right.right = current.left
      current.onShow()

      width = element[0].clientWidth
      console.log width, "width"

      swiper = Swipe element,
        width: width
        onStart: (x)->
          console.log "start"

        onMove: (offset)->

          current.updatePosition(offset)
          current.right.updatePosition(offset+width) if offset < 0
          current.left.updatePosition(offset-width) if offset > 0

        onEnd: (offset, aniRatio)->
          if aniRatio
            @swiper.setDisable true
            time = aniRatio * 0.4
            prop = "all #{time}s #{timing}"
            if offset > 0
              offset = 1
            else if offset < 0
              offset = -1
            @animateTo(offset, prop)
          else
            @resetState()
  )




