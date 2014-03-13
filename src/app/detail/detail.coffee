angular.module('app.detail', ['app.detail.image'])

  .controller( 'DetailCtrl', ($scope, Many, $routeParams, $timeout, Service, Popup, MESSAGE, Nav) ->

    console.log 'DetailCtrl'

    # Init locals
    collection = Many('events')
    e = null

    $scope.$on '$scopeUpdate', ->
      $scope.e = e = collection.get Number($routeParams.id)
      if !e.$resolved
        #Loading will end automatically when promise resolved or rejected
        Popup.loading e.$promise, null, MESSAGE.LOAD_FAILED
      #reset the tab state
      $scope.activeTab='info'
      e.$promise.then ->
        #Finish loading detail info
        #Set page title to event title
        $scope.setPageTitle e.title
        #Check if I am owner
        if $scope.meta.user and e.starter
          $scope.IamOwner = $scope.meta.user.id is e.starter.id
        #Check if I am In
        $scope.IamIn = Number Boolean $scope.meta.user and _.find(e.attendees, id:$scope.meta.user.id)
        #Bug: scrollView is override by the last one
        #$scope.scrollView.scrollTo(0,0)
        $timeout -> $scope.$broadcast('scroll.resize')


    #TODO:
    #Default setting noRepeat=2000, noLogin=false
#    actions =
#      register: onRegister
#      unRegister: onUnRegister
#      follow:  onFollow
#      share:
#        noLogin: yes
#        handler: onShare
#      upload: onUpload
#    $scope.onAction = (action)->


    #Refresh the detail info
    $scope.onRefresh = ()->
      console.log "refresh in detail ctrl"
      collection.get e.id, true, ->
        $scope.$broadcast('scroll.refreshComplete')

    #Register for the event or unregister
    $scope.onRegister = (quit)->
      if Service.noRepeat('register') and $scope.loginOrPopup()
        if !$scope.IamIn
          e.post('attendees').then (d)->
            e.attendees = d
            $scope.IamIn = 1
            Popup.alert("报名成功")
        else
          Popup.alert('已加入')

    $scope.onUnRegister = ->
      if Service.noRepeat('unregister') and $scope.loginOrPopup()
        if $scope.IamIn
          Popup.confirm('确定退出吗？').then ->
            e.customDELETE('attendees').then (d)->
              e.attendees = d
              $scope.IamIn = 0
        else
          Popup.alert('已退出')


    $scope.onFollow = ->
      if Service.noRepeat('follow') and $scope.loginOrPopup()
        if !_.find(e.followers, id:$scope.meta.user.id)
          e.post('followers').then (d)->
            e.followers = d
            Popup.alert("关注成功")
        else
          Popup.alert("已关注")

    #Share the event
    $scope.onShare = ->

      Popup.options(MESSAGE.SHARE_OPTS).then (index)->
        #Share to sina weibo
        if index is 0
          if $scope.loginOrPopup()
            if $scope.meta.user.origin is 's'
              $scope.openShare()
            else
              Popup.alert "需要用新浪微博登陆！"
          #Share to wechat
        else if index is 1
          if $scope.inWeChat()
            Popup.alert "点击右上方分享按钮"
          else
            Popup.alert "在微信中打开并分享！"


    #Upload a picture
    $scope.onUpload = ->
      if $scope.loginOrPopup()
        if $scope.inWeChat() and $scope.isAndroid()
          Popup.alert "微信中不支持上传<br>点击右上方分享按钮<br>并在浏览器中打开"
        else
          Nav.go 'ImageUploadCtrl', id: e.id

    #Edit the event
    $scope.onEdit = ->
      Nav.go('EditCtrl', id: e.id) if $scope.loginOrPopup()
    #Make a comment
    $scope.onComment = ->
      if Service.noRepeat('comment') and $scope.loginOrPopup()
        $scope.$broadcast('onComment')

    #View picture
    $scope.slideView = (img)->
      Nav.go 'ImageSlideCtrl', id: e.id

    #Open share modal
    $scope.openShare = ->

      Popup.modal "modal/comment.tpl.html",
        title: MESSAGE.SHARE
        comment: "##{e.title}#"
        onSubmit: (comment)->
          if comment and Service.noRepeat('comment',3000)
            e.post('share', content:comment).then (ret)->
              if ret.error
                Popup.alert("分享失败")
              else
                Popup.alert("分享成功")
            @$close()
  )

  .controller( 'CommentCtrl', ($scope, $timeout, Popup, Service, MESSAGE) ->

    console.log "comment ctrl"

    #Refresh comment list
    $scope.onRefresh = ()->
      console.log "refresh in commenttrl"
      $scope.e.getList('comments').then (d)->
        $scope.e.comment_set = d
        $scope.$broadcast('scroll.refreshComplete')
        $scope.$broadcast('scroll.resize')

    #Delete a comment
    $scope.onCommentDel = (id)->
      $scope.e.one('comments', id).remove().then ->
        $scope.e.comment_set.splice _.findIndex($scope.e.comment_set, id:id), 1
        $scope.$broadcast('scroll.resize')

    $scope.onMore = (cb)->  $timeout (-> cb()),1000


    #Make a comment
    $scope.$on 'onComment', ->

      Popup.modal "modal/comment.tpl.html",
        title: MESSAGE.COMMENT
        onSubmit: (comment)->
          if comment and Service.noRepeat('comment',3000)
            $scope.e.post('comments', body:comment).then (d)->
              #Should refresh here
              $scope.e.comment_set.unshift(d)
              $scope.$broadcast('scroll.resize')
            @$close()

  )

