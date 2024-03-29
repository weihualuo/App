angular.module('app.advice', [])
  .controller( 'AdviceCtrl', ($scope, $controller, Nav, ToggleModal, Popup, MESSAGE) ->
    console.log 'AdviceCtrl'
    $scope.listCtrl = $controller('ListCtrl', {$scope:$scope, name: 'advices'})

    $scope.$on 'rightButton', (e, index)->
      if index is 0 and $scope.isLogin(yes)
        ToggleModal
          id: 'advice'
          template: "<modal class='profile-win'></modal>"
          $aniIn: 'from-center'
          $aniOut: 'from-center'
          url: 'advice/newAdvice.tpl.html'
          controller: 'NewAdviceCtrl'

    $scope.onAdviceView = (obj)->
      Nav.go
        name: 'adviceDetail'
        param: id:obj.id
        push: yes
    this

  )
  .controller('AdviceDetailCtrl', ($scope, $controller, When, Many, Nav, $routeParams, MESSAGE, Popup, ToggleModal)->
    console.log 'AdviceDetailCtrl'
    # Init locals
    obj = null
    listCtrl = $controller 'ListCtrl', {$scope:$scope, name:'comments'}
    listCtrl.auto = off

    $scope.$on '$scopeUpdate', (e)->
      $scope.obj = obj = Many('advices').get parseInt($routeParams.id)
      listCtrl.reload({}, {parent:'advices',pid:$routeParams.id})
      When(obj).then ->
        user = $scope.meta.user
        $scope.isOwner = user and user.id is obj.author.id

    $scope.onBack = ->
      Nav.back name:'advices'

    $scope.onMark = ->
      if not $scope.noRepeatAndLogin('mark') then return
      obj.marked = !obj.marked
      if obj.marked
        obj.post('mark')
      else
        obj.customDELETE('mark')

    $scope.onComment = ->
      Nav.go
        name: 'comments'
        param:
          parent:'advices'
          pid:obj.id
        data:
          obj:obj
        push: yes

    #right button of main bar
    $scope.$on 'rightButton', $scope.onComment

    $scope.onEdit = ->
      ToggleModal
        id: 'advice'
        template: "<modal class='profile-win'></modal>"
        $aniIn: 'from-center'
        $aniOut: 'from-center'
        url: 'advice/newAdvice.tpl.html'
        controller: 'NewAdviceCtrl'
        locals:
          obj:obj

    this
  )
  .controller('NewAdviceCtrl', ($scope, Many, Popup, MESSAGE, Service)->

    collection = $scope.collection or Many('advices')
    $scope.data = data = {}
    obj = $scope.obj
    if obj
      angular.copy(obj, data)
      data.image = null

    uploadImage = (image, advice)->
      promise = Service.uploadFile(image:image, '/api/photos')
      promise.then(
        (ret)->
          #console.log ret
          image = JSON.parse(ret)
          pros =  advice.patch("image":image.id)
          pros.then( -> obj.image = image if obj).finally ->
            Popup.alert MESSAGE.SAVE_OK
            $scope.modal.close()
            collection.refresh() if collection.objects and not obj
          pros
        ()->
          Popup.alert MESSAGE.UPLOAD_FAILED
          null
      )

    validateMsg =
      required:
        title: MESSAGE.REQ_TITLE
        desc: MESSAGE.REQ_DESC

    $scope.onSubmit = ->

      if Service.noRepeat('submit') and Service.validate($scope.form, validateMsg)
        param = {}
        param.title = data.title
        param.desc = data.desc
        if obj
          p1 = obj.patch(param)
        else
          p1 = collection.new(param)
        promise = p1.then(
          (ret)->
            if obj
              angular.extend(obj, param)
            if data.image
              return uploadImage(data.image, ret)
            else
              Popup.alert MESSAGE.SAVE_OK
              $scope.modal.close()
              collection.refresh() if collection.objects and not obj
          ()->
            Popup.alert MESSAGE.SUBMIT_FAILED
        )
        Popup.loading promise, {showWin:yes}

    this
  )
  .controller('CommentCtrl', ($scope, $controller, Nav, ToggleModal, Popup)->

    #console.log 'CommentCtrl', $scope.obj
    ctrl = this
    listCtrl = $controller 'ListCtrl', {$scope:$scope, name:'comments'}

    $scope.onBack = ->
      Nav.back name:'advices'

    $scope.$on 'content.closed', ->
      #unregister animation hook
      ctrl.unregister()
      $scope.onBack()

    $scope.$on 'parent.event', $scope.onBack

    $scope.data = data = {}
    $scope.status = 'idle'
    $scope.onRight = ->
      if $scope.status is 'idle'
        $scope.status = 'edit'
      else if $scope.status is 'edit'
        if data.comment
          $scope.status = 'send'
          $scope.collection.new(
            body: data.comment
          ).then ->
            data.comment = ''
            $scope.status = 'idle'
            $scope.obj?.reply_num++
            listCtrl.refresh()

    this
  )