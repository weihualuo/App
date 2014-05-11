angular.module('app.advice', [])
  .controller( 'AdviceCtrl', ($scope, $controller, Nav, ToggleModal, Popup, MESSAGE) ->
    console.log 'AdviceCtrl'
    $scope.listCtrl = $controller('ListCtrl', {$scope:$scope, name: 'advices'})

    $scope.$on 'rightButton', (e, index)->
      if index is 0 and $scope.isLogin(yes)
        ToggleModal
          id: 'advice'
          template: "<modal class='fade-in-out profile-win'></modal>"
          url: 'advice/newAdvice.tpl.html'
          controller: 'NewAdviceCtrl'

    $scope.onAdviceView = (obj)->
      Nav.go
        name: 'adviceDetail'
        param: id:obj.id
        push: yes
    this

  )
  .controller('AdviceDetailCtrl', ($scope, $controller, Many, Nav, $routeParams, MESSAGE, Popup, ToggleModal)->
    console.log 'AdviceDetailCtrl'
    # Init locals
    obj = null
    listCtrl = $controller 'ListCtrl', {$scope:$scope, name:'comments'}
    listCtrl.auto = off

    $scope.$on '$scopeUpdate', (e)->
      $scope.obj = obj = Many('advices').get parseInt($routeParams.id)
      Popup.loading(obj.$promise) if not obj.$resolved
      listCtrl.reload({}, {parent:'advices',pid:$routeParams.id})

    $scope.onBack = ->
      Nav.back name:'advices'

    $scope.onComment = ->
      Nav.go
        name: 'comments'
        param:
          parent:'advices'
          pid:obj.id
        data: restParent:obj
        push: yes
      return

    #right button of main bar
    $scope.$on 'rightButton', $scope.onComment

    this
  )
  .controller('NewAdviceCtrl', ($scope, Many, Popup, MESSAGE, Service)->

    collection = Many('advices')
    $scope.data = data = {}

    uploadImage = (image, advice)->
      promise = Service.uploadFile(image:image, '/api/photos')
      promise.then(
        (ret)->
          console.log ret
          image = JSON.parse(ret)
          p =  advice.patch("image":image.id)
          p.finally ->
            Popup.alert MESSAGE.SAVE_OK
            $scope.modal.close()
            collection.refresh() if collection.objects
          p
        ()->
          Popup.alert MESSAGE.UPLOAD_FAILED
          null
      )

    $scope.onSubmit = ->
      param = {}
      param.title = data.title
      param.body = data.body
      promise = collection.new(param).then(
        (ret)->
          window.advice = ret
          if data.image
            return uploadImage(data.image, ret)
          else
            Popup.alert MESSAGE.SAVE_OK
            $scope.modal.close()

        ()->
          Popup.alert MESSAGE.SUBMIT_FAILED
      )
      Popup.loading promise, {showWin:yes}

    this
  )
  .controller('CommentCtrl', ($scope, $controller, Nav, ToggleModal, Popup)->

    console.log 'CommentCtrl'
    ctrl = this
    listCtrl = $controller 'ListCtrl', {$scope:$scope, name:'comments'}

    $scope.onBack = ->
      Nav.back name:'advices'

    $scope.$on 'content.closed', ->
      #unregister animation hook
      ctrl.unregister()
      $scope.onBack()

    $scope.$on 'parent.event', $scope.onBack

    $scope.onEdit = ->

      if not $scope.noRepeatAndLogin('comment') then return
      ToggleModal
        id: 'comment'
        template: "<modal class='fade-in-out'></modal>"
        url: "modal/comment.tpl.html"
        closeOnBackdrop: yes
        success: (comment)->
          if comment
            Popup.loading $scope.collection.new(
              body: comment
            ).then ->
              listCtrl.refresh()
              null

  )