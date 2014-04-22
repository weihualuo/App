
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
  .controller( 'PhotoDetailCtrl', ($scope, $controller, $element, $timeout, Nav, Env, Service, ToggleModal, ImageSlide, TransUtil)->
    #extend from ListCtrl
    #angular.extend($scope, Nav.data())
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

    $scope.transIn = TransUtil.rectTrans($scope.rect)
    $scope.transOutFn = ->
      rect = $scope.scrollView?.getItemRect($scope.index)
      TransUtil.rectTrans(rect)

    $scope.toggleMenu = ->
      $scope.hasMenu = env.noSide
      env.noHeader = not env.noHeader
      env.noSide = not env.noSide
      $scope.$emit('envUpdate')


    $scope.$on 'gallery.slide', (e, index)->
      $scope.index = index
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
      Nav.go
        name: 'photoInfo'
        push: yes
        data: image: $scope.objects[index]
      return
#      ToggleModal
#        id: 'infoView'
#        template: "<side-pane position='right' class='pane-image-info popup-in-right'></side-pane>"
#        url: "modal/imageInfo.tpl.html"
#        hash: 'info'
#        locals:
#          image: $scope.objects[index]

    $scope.onCtrl = (e, id)->

      e.stopPropagation()
      if not Service.noRepeat('slideCtrl', 500)
        return

      switch id
        when 'info'
          onImageInfo($scope.index)
        when 'close'
          $scope.displayCtrl = no
          Nav.back({name:'photos'})

        when 'add'
          if $scope.isLogin(yes)
            ToggleModal
              id: 'add-to-ideabook'
              template: "<div class='popup-win fade-in-out'></div>"
              controller: 'addIdeabookCtrl'
              url: 'modal/addIdeabook.tpl.html'
              locals:
                user: $scope.meta.user
                image: $scope.objects[$scope.index]

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
  .controller('PhotoInfoCtrl', ($scope, Env, Nav)->

    ctrl = this
    Env.photoInfo = Env.photoDetail

    $scope.$on 'content.closed', ->
      ctrl.unregister()
      $scope.onClose()

    $scope.onClose = ->
      Nav.back name:'photoDetail'

    this
  )