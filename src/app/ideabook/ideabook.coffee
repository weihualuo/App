
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

      resize = ->
        height = element[0].offsetHeight
        width = Math.round(obj.width*(height/obj.height))+40
        element.css width: width+'px'
      resize()
      scope.$watch 'editMode', (value, old)->
        if !value isnt !old then resize()
        if value and scope.$last
          scope.scrollView.scrollTo(0, 0)
  )

  .controller( 'IdeabookCtrl', ($scope, $controller, Nav)->
    #extend from ListCtrl
    $scope.listCtrl = $controller('ListCtrl', {$scope:$scope, name: 'ideabooks'})


    $scope.onUser = (e, user)->
      e.stopPropagation()
      Nav.go
        name: 'userDetail'
        param: id:user.id
        push: yes

    $scope.onIdeaBookView = (obj)->
      Nav.go
        name: 'ideabookDetail'
        param: id:obj.id
        push: yes

    this

  )
  .controller('IdeabookDetailCtrl', ($scope, $controller, $routeParams, $timeout, Many, Env, Nav, Popup, When, ToggleModal, MESSAGE)->

    console.log 'IdeabookDetailCtrl'
    # Init locals
    obj = null
    $scope.listCtrl = listCtrl = $controller 'ListCtrl', {$scope:$scope, name:'pieces'}
    listCtrl.auto = off

    $scope.$on '$scopeUpdate', ->
      $scope.obj = obj = Many('ideabooks').get parseInt($routeParams.id)
      #Popup.loading(obj.$promise) if not obj.$resolved
      listCtrl.reload({}, {parent:'ideabooks',pid:$routeParams.id})
      When(obj).then ->
        user = $scope.meta.user
        $scope.marked = user and user.id in obj.marks
        $scope.isOwner = user.id is obj.author.id

    $scope.onBack = ->
      Nav.back({name:'ideabooks'})

    $scope.onMark = ->
      if not $scope.noRepeatAndLogin('mark') then return
      $scope.marked = !$scope.marked
      if $scope.marked
        obj.post('mark')
      else
        obj.customDELETE('mark')

    $scope.onComment = ->
      Nav.go
        name: 'comments'
        param:
          parent:'ideabooks'
          pid:obj.id
        push: yes
    #right button of main bar
    $scope.$on 'rightButton', ->
      if $scope.editMode
        $scope.editMode = false
      else
        $scope.onComment()

    $scope.onText = ->
      if $scope.editMode
        $scope.select = obj

    $scope.onUnitView = (p)->

      if $scope.editMode
        $scope.select = p
        return

      Nav.go
        name: 'ideabookUnit'
        param: $routeParams
        data:
          name: 'ideabookUnit'
          index: $scope.objects.indexOf(p)
          getDataAt: (index)-> $scope.objects[index].image
          getElementIndex: (index)-> index+1
        push: yes
        inherit: yes

    $scope.onCommentPiece = (e, p)->
      e.stopPropagation()
      Nav.go
        name: 'comments'
        param:
          parent:'pieces'
          pid:p.id
        push: yes

    $scope.onEdit = ->
      $scope.editMode = !$scope.editMode

    $scope.onSave = ->
      console.log obj.$dirty
      if obj.$dirty
        obj.$dirty = no
        obj.patch(title:obj.title, desc:obj.desc)

      for p in $scope.objects
        console.log p.$dirty
        if p.$dirty
          p.$dirty = no
          p.patch(desc:p.desc)

    $scope.$watch 'editMode', (value, old)->
      Env.ideabookDetail.right = if value then ['完成'] else ['评论']
      $scope.select = if value then obj else null
      if old
        #wait for select digest over
        $timeout $scope.onSave

    $scope.$watch 'select', (select, old)->
      if old
        old.$dirty = $scope.form.$dirty
      if select
        if select.$dirty
          $scope.form.$setDirty()
        else
          $scope.form.$setPristine()
      console.log $scope.form

    $scope.onLike = (e, p)->
      e.stopPropagation()

    this
  )
  .controller('IdeabookUnitCtrl', ($scope, $controller, $timeout, When, Env, Nav, Many, $routeParams, ImageSlide, TransUtil, Service)->

    #Set env to hide or show side & header
    env = Env.ideabookUnit
    env.noHeader = false
    $timeout (->
      env.noHeader = true
    ), 500
    #Wait for 1 second to enable ctrl
    ready = no
    $timeout (-> ready = yes), 1000


    listCtrl = $controller 'ListCtrl', {$scope:$scope, name:'pieces'}
    listCtrl.auto = off
    $scope.index ?= 0

    $scope.$on '$scopeUpdate', ->
      listCtrl.reload({}, {parent:'ideabooks',pid:$routeParams.id})

    $scope.transFn = ->
      rect = $scope.scrollView?.getItemRect($scope.index+1)
      TransUtil.rectTrans(rect)

    $scope.$on 'gallery.slide', (e, index)->
      $scope.index = index
      $scope.p = $scope.objects[index]

    $scope.$on 'scroll.reload', ->
      images = (p.image for p in $scope.objects)
      index = $scope.index
      $scope.p = $scope.objects[index]
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
    #Request the list without cache
    list = collection.list(author: $scope.user.id)
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