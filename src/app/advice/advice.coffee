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
    collection = Many('advices')
    obj = null

    $scope.$on '$scopeUpdate', ->
      $scope.obj = obj = collection.get parseInt($routeParams.id)
      Popup.loading(obj.$promise) if not obj.$resolved

    $scope.listCtrl = $controller 'SubListCtrl',
      $scope:$scope
      Config:
        name: 'advices'
        sub: 'reply'
        param: -> reply:obj.id
        flag: 'obj'

    $scope.onBack = ->
      Nav.back name:'advices'

    $scope.onComment = ->
      if not $scope.noRepeatAndLogin('comment') then return
      ToggleModal
        id: 'comment'
        template: "<side-pane position='right' class='popup-in-right'></side-pane>"
        url: "modal/comment.tpl.html"
        scope: $scope
        closeOnBackdrop: yes
        success: (comment)->
          if comment
            Popup.loading collection.new(
              body: comment
              reply: obj.id
            ).then (data)->
              obj.replies.unshift data
              null

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