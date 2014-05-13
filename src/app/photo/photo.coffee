
angular.module('app.photo', ['NewGallery', 'Slide'])

  .directive('imageThumb', (ImageUtil)->

    restrict:'AC'
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
            element.prepend image
      #image.onerror = ->
      #console.log "onerror", scope.obj.id
      if not scope.dynamic
        element.triggerHandler 'dynamic.add'

  )
  .controller( 'PhotoCtrl', ($scope, $controller, $element, $timeout, $filter, Many, Popup, Nav, Env, ToggleModal) ->
    console.log 'PhotoCtrl'

    #extend from ListCtrl
    $scope.listCtrl =  $controller('ListCtrl', {$scope:$scope, name: 'photos'})

    $scope.$on 'rightButton', (e, index)->
      #upload
      if index is 0 and $scope.isLogin(yes)
        ToggleModal
          id: 'upload'
          template: "<modal class='fade-in-out profile-win'></modal>"
          url: 'my/myUpload.tpl.html'
          controller: 'myUploadCtrl'
          scope: $scope

    $scope.onImageView = (e)->
      #Delegate mode in large list
      item = e.target
      if item.tagName is 'IMG'
        item = item.parentNode
      if item.tagName is 'LI'
        obj = angular.element(item).scope().obj
        Nav.go
          name: 'photoDetail'
          data: index: $scope.objects.indexOf(obj)
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
    env = Env[$scope.name or 'photoDetail']
    env.noHeader = yes
    env.noSide = yes

    $scope.toggleMenu = ->
      $scope.hasMenu = env.noSide
      env.noHeader = not env.noHeader
      env.noSide = not env.noSide

    #Overidable function
    $scope.getDataAt ?= (index)-> $scope.objects[index]
    $scope.getDataLen ?= -> $scope.objects.length
    $scope.getElementIndex ?= (index)-> index

    $scope.transFn = ->
      index = $scope.getElementIndex($scope.index)
      rect = $scope.scrollView?.getItemRect(index)
      TransUtil.rectTrans(rect)

    $scope.$on 'gallery.slide', (e, index)->
      $scope.index = index
      if $scope.haveMore and index+6 > $scope.objects.length
        $scope.$emit 'scroll.moreStart'

    $scope.$on 'tag.view', (e, tag)->
      Nav.go
        name: 'productDetail'
        param: id:tag.product
        push: yes

    initSlide = ->
      slideCtrl = $scope.slideCtrl
      slideCtrl.initSlides(ImageSlide, $scope.index)

    if $scope.objects
      $scope.objects.$promise.then initSlide
    else
      $scope.$on 'scroll.reload', initSlide

    onImageInfo = (index)->
      Nav.go
        name: 'photoInfo'
        param: id: $scope.getDataAt(index).id
        push: yes
      return

    onAddIdeabook = (index)->
      if $scope.isLogin(yes)
        ToggleModal
          id: 'add-to-ideabook'
          template: "<modal class='fade-in-out'></modal>"
          controller: 'addIdeabookCtrl'
          url: 'modal/addIdeabook.tpl.html'
          locals:
            user: $scope.meta.user
            image: $scope.getDataAt(index)

    #Wait for 1 second to enable ctrl
    ready = no
    $timeout (-> ready = yes), 1000

    $scope.onCtrl = (e, id)->

      e.stopPropagation()
      if not Service.noRepeat('slideCtrl', 500)
        return

      switch id
        when 'info'
          onImageInfo($scope.index)
        when 'close'
          if not ready then return
          $scope.displayCtrl = no
          Nav.back({name:'photos'})

        when 'add'
          onAddIdeabook($scope.index)

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
  .controller('PhotoInfoCtrl', ($scope, $controller, $routeParams, Many, Popup, Nav)->

    ctrl = this
    obj = null
    listCtrl = $controller 'ListCtrl', {$scope:$scope, name:'pieces'}
    listCtrl.auto = off
    $scope.$on '$scopeUpdate', ->
      $scope.obj = obj = Many('photos').get parseInt($routeParams.id)
      listCtrl.reload({}, {parent:'photos',pid:$routeParams.id})

    $scope.$on 'content.closed', ->
      #unregister animation hook
      ctrl.unregister()
      $scope.onBack()

    $scope.onBack = ->
      Nav.back name:'photos'

    $scope.$on 'parent.event', $scope.onBack

    $scope.onUser = (user)->
      Nav.go
        name: 'userDetail'
        param: id:user.id

    $scope.onIdeabook = (id)->
      Nav.go
        name: 'ideabookDetail'
        param: id:id

    $scope.onComment = ->
      Nav.go
        name: 'comments'
        param:
          parent:'photos'
          pid:obj.id
        push: yes

    this
  )