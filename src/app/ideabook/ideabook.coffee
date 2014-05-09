
angular.module('app.ideabook', [])

  .directive('ideabookThumb', (ImageUtil)->

    restrict:'AC'
    link: (scope, element, attr)->
      image = null
      index = parseInt(attr.index)
      pieces = scope.obj.pieces
      if index >=  pieces.length then return
      obj = pieces[index].image

      element.on 'dynamic.remove', ->
        #console.log "dynamic.remove", scope.obj.id
        if image
          image.remove()
          image = null
      element.on 'dynamic.add', ->
        #console.log "dynamic.add", scope.obj.id
        image = new Image()
        image.src = ImageUtil.ideabookThumb(obj)
        image.onload = ->
          element.prepend image
      #image.onerror = ->
      #console.log "onerror", scope.obj.id
      element.triggerHandler 'dynamic.add'

  )
  .directive('ideabookUnit', (ImageUtil)->
    restrict:'C'
    link: (scope, element, attr)->
      obj = scope.p?.image
      if not obj then return
      image = new Image()
      image.src = ImageUtil.best(obj)
      image.onload = ->
        element.prepend image

      #console.log element[0].offsetHeight
#      element.ready ->
#        height = element[0].offsetHeight
#        width = Math.round obj.width*(height/obj.height)
#        #element.css width: width+'px'
#        console.log height, width, obj.height, obj.width
  )

  .controller( 'IdeabookCtrl', ($scope, $controller, Nav)->
    #extend from ListCtrl
    $scope.listCtrl = $controller('ListCtrl', {$scope:$scope, name: 'ideabooks'})

    $scope.onIdeaBookView = (obj)->
      Nav.go
        name: 'ideabookDetail'
        param: id:obj.id
        push: yes

    this

  )
  .controller('IdeabookDetailCtrl', ($scope, $routeParams, Many, Nav, Popup, ToggleModal, MESSAGE)->

    console.log 'IdeabookDetailCtrl'
    # Init locals
    collection = Many('ideabooks')
    obj = null

    $scope.$on '$scopeUpdate', ->
      $scope.obj = obj = collection.get parseInt($routeParams.id)
      obj.$promise.then ->
        user = $scope.meta.user
        $scope.marked = user and user.id in obj.marks
      Popup.loading(obj.$promise) if not obj.$resolved

    $scope.onBack = ->
      Nav.back({name:'ideabooks'})


    $scope.onMark = ->
      if not $scope.noRepeatAndLogin('mard') then return
      $scope.marked = !$scope.marked
      if $scope.marked
        obj.post('mark')
      else
        obj.customDELETE('mark')

    $scope.onComment = ->
      if not $scope.noRepeatAndLogin('comment') then return
      ToggleModal
        id: 'comment'
        template: "<side-pane position='right' class='popup-in-right'></side-pane>"
        url: "modal/comment.tpl.html"
        success: (comment)->
          if comment
            Popup.loading collection.new(
              body: comment
              reply: obj.id
            ).then (data)->
              obj.replies.unshift data
              null

    $scope.onUnitView = (p)->
      Nav.go
        name: 'ideabookUnit'
        param: $routeParams
        data: index: $scope.obj.pieces.indexOf(p)
        push: yes
        inherit: yes
    this
  )
  .controller('IdeabookUnitCtrl', ($scope, $timeout, Env, Nav, Many, $routeParams, ImageSlide, TransUtil, Service)->

    #Set env to hide or show side & header
    env = Env.ideabookUnit
    env.noHeader = false
    $timeout (->
      env.noHeader = true
      $scope.$emit('envUpdate')
    ), 500

    #Wait for 1 second to enable ctrl
    ready = no
    $timeout (-> ready = yes), 1000

    collection = Many('ideabooks')
    $scope.obj ?= collection.get parseInt($routeParams.id)
    $scope.index ?= 0

    $scope.transFn = ->
      rect = $scope.scrollView?.getItemRect($scope.index+1)
      TransUtil.rectTrans(rect)

    $scope.$on 'gallery.slide', (e, index)->
      $scope.index = index
      $scope.p = $scope.obj.pieces[index]

    $scope.obj.$promise.then ->
      images = (p.image for p in $scope.obj.pieces)
      index = $scope.index
      $scope.p = $scope.obj.pieces[index]
      #console.log images, $scope.index
      slideCtrl = $scope.slideCtrl
      slideCtrl.initSlides(ImageSlide, images, $scope.index)

    $scope.onCtrl = (e, id)->

      e.stopPropagation()
      return no if not Service.noRepeat('slideCtrl', 500)
      switch id
        when 'slide'
          if ready then Nav.back(name:'ideabooks')

    this
  )
  .controller('addIdeabookCtrl', ($scope, Many, Service, Restangular, Popup, MESSAGE)->
    # Operation on the collection will cause inconsistent of home list
    # due to listCtrl use cache mechanisam
    # New sulotion, Add sub id to list
    collection = Many('ideabooks', 'my')

    $scope.ideabooks = ideabooks = [{id:0, title: MESSAGE.NEW_IDEABOOK, pieces:[]}]
    $scope.ideabook = ideabooks[0]
    param = author: $scope.user.id
    #Request the list without cache
    list = collection.list(param)
    #Tricky: I prepend to list after new a item, but promise will resove with
    # the same value last time resolved, so use list but data here
    list.$promise.then (data)-> angular.forEach list, (v)->ideabooks.push v

    saveToIdeabook =(ideabook)->
      data =
        image: $scope.image.id
        desc: $scope.desc
      ideabook.post('pieces', data).then(
        ()->
          Popup.alert MESSAGE.SAVE_OK
          $scope.modal.close()
          null
        (error)->
          msg = if error.data.image then MESSAGE.IMAGE_EXIST else  MESSAGE.SAVE_NOK
          Popup.alert msg
          null
      )

    $scope.onSave = ()->
      if not Service.noRepeat('saveIdeabook') then return

      ideabook = $scope.ideabook
      id = $scope.image.id
      title = $scope.title

      if ideabook.id is 0
        if not title
          return Popup.alert MESSAGE.REQ_TITLE
        else if _.find(ideabooks, title:title)
          return Popup.alert MESSAGE.TITLE_EXIST

      for p in ideabook.pieces
        if p.image.id is id
          return Popup.alert MESSAGE.IMAGE_EXIST

      #Create a new ideabook
      if ideabook.id is 0
        promise = collection.new(title:title, yes).then(
          (newObj)->
            saveToIdeabook(newObj)

          (error)->
            msg = if error.data.title then MESSAGE.TITLE_EXIST else  MESSAGE.SAVE_NOK
            Popup.alert msg
            null
        )
      else
        promise = saveToIdeabook(ideabook)
      Popup.loading promise, {showWin:yes}
      promise

    this
  )