
angular.module('app.photo', ['NewGallery', 'Slide'])

  .directive('imageThumb', (ImageUtil)->

    restrict:'C'
    link: (scope, element)->

      image = null
      element.on 'dynamic.remove', ->
        #console.log "dynamic.remove", scope.obj.id
        if image
          image.remove()
          image = null
      element.on 'dynamic.add', ->
        #console.log "dynamic.add", scope.obj.id
        if not image
          image = new Image()
          image.src = ImageUtil.thumb(scope.obj)
          image.onload = ->
            element.append image
      #image.onerror = ->
      #console.log "onerror", scope.obj.id
      if not scope.dynamic
        element.triggerHandler 'dynamic.add'

  )
  .controller( 'PhotoCtrl', ($scope, $controller, $element, $timeout, $filter, Many, Popup, Nav) ->
    console.log 'PhotoCtrl'

    #extend from ListCtrl
    $scope.listCtrl =  $controller('ListCtrl', {$scope:$scope, name: 'photos'})

    $scope.onImageView = (e)->
      #Delegate mode in large list
      item = e.target
      if item.tagName is 'IMG'
        item = item.parentNode
      if item.tagName is 'LI'
        obj = angular.element(item).scope().obj
        data =
          rect: item.getBoundingClientRect()
          index: $scope.objects.indexOf(obj)
        Nav.go
          name: 'photoDetail'
          data: data
          push: yes
          inherit: yes
      return
    this
  )

  .controller( 'PhotoDetailCtrl', ($scope, $controller, $element, $timeout, Nav, Env, Service, TogglePane, ImageSlide)->
    #extend from ListCtrl
    angular.extend($scope, Nav.data())
    $scope.index ?= 0
    $scope.listCtrl ?=  $controller('ListCtrl', {$scope:$scope, name: 'photos'})
    slideCtrl = null

    #Set env to hide or show side & header
    env = Env.photoDetail
    env.noHeader = false
    env.noSide = false
    $timeout (->
      env.noHeader = true
      env.noSide = true
      $scope.$emit('envUpdate')
    ), 1000

    @leave = (done)->
      if trans = $scope.transformer
        rect = $scope.scrollView?.getItemRect($scope.index)
        trans(rect, done)
      else
        done()

    @enter = (done)->
      console.log "entering"
      done(-> console.log "complete")

    $scope.onClose = (index)->
      env.noHeader = false
      env.noSide = false
      $scope.$emit('envUpdate')

      close = -> Nav.back({name:'photos'})
      if trans = $scope.transformer
        rect = $scope.scrollView?.getItemRect(index)
        trans(rect, close)
      else
        close()

    $scope.toggleMenu = ->
      $scope.hasMenu = env.noSide
      env.noHeader = not env.noHeader
      env.noSide = not env.noSide
      $scope.$emit('envUpdate')


    $scope.$on 'gallery.slide', (e, index)->
      $scope.title = $scope.objects[index].title
      if $scope.haveMore and index+6 > $scope.objects.length
        $scope.$emit 'scroll.moreStart'

    $scope.$on 'tag.view', (e, tag)->
      Nav.go
        name: 'productDetail'
        param: id:tag.product
        push: yes

    initSlide = ->
      slideCtrl = $scope.slideCtrl
      slideCtrl.initSlides(ImageSlide, $scope.objects, $scope.index)

    if $scope.objects
      $scope.objects.$promise.then initSlide
    else
      $scope.$on 'scroll.reload', initSlide


    onImageInfo = (index)->
      TogglePane
        id: 'infoView'
        template: "<side-pane position='right' class='pane-image-info popup-in-right'></side-pane>"
        url: "modal/imageInfo.tpl.html"
        hash: 'info'
        locals:
          image: $scope.objects[index]

    $scope.onCtrl = (e, id)->

      e.stopPropagation()
      if not Service.noRepeat('slideCtrl', 600)
        return

      switch id
        when 'info'
          onImageInfo(slideCtrl.getCurrentIndex())
        when 'close'
          $scope.displayCtrl = no
          $scope.index = slideCtrl.getCurrentIndex()
          Nav.back({name:'photos'})

        when 'prev'
          slideCtrl.prev()
        when 'next'
          slideCtrl.next()
        when 'slide'
          $scope.displayCtrl = not $scope.displayCtrl
          if not $scope.displayCtrl and $scope.hasMenu
            $scope.toggleMenu()
          $scope.$broadcast('slide.click')

    this
  )