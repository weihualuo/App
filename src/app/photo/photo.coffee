
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
#    env = Env.photoDetail
#    env.noHeader = false
#    env.noSide = false
#    $timeout (->
#      env.noHeader = true
#      env.noSide = true
#      #$scope.$emit('envUpdate')
#    ), 500

    #Wait for 1 second to enable ctrl
    ready = no
    $timeout (-> ready = yes), 1000

    $scope.transFn = ->
      index = $scope.index
      index = $scope.scrollIndex(index) if $scope.scrollIndex
      rect = $scope.scrollView?.getItemRect(index)
      TransUtil.rectTrans(rect)

    $scope.toggleMenu = ->
      env = $scope.env
      $scope.hasMenu = env.noSide
      env.noHeader = not env.noHeader
      env.noSide = not env.noSide
      #$scope.$emit('envUpdate')


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
      id = parseInt $scope.objects[index].id
      ToggleModal
        id: 'info'
        template: "<side-pane position='right' class='pane-image-info popup-in-right'></side-pane>"
        url: "photo/photoInfo.tpl.html"
        closeOnBackdrop: yes
        locals:
          obj: $scope.collection.get id
        success: (ret)->
          Nav.go
            name:  ret.name
            param: id:ret.id
            push: yes

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
          if $scope.isLogin(yes)
            ToggleModal
              id: 'add-to-ideabook'
              template: "<modal class='fade-in-out'></modal>"
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
#  .controller('PhotoInfoCtrl', ($scope, Many, Popup, Nav)->
#
#    collection = Many('photos')
#    $scope.obj = obj = collection.get parseInt($scope.id)
#    Popup.loading(obj.$promise) if not obj.$resolved
#
#    $scope.onUser = (id)->
#
#    $scope.onIdeabook = (id)->
#      $scope.modal.close()
#      Nav.go
#        name: 'ideabookDetail'
#        param: id:id
#        push: yes
#
#    this
#  )