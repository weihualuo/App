angular.module('app.my', [])

  .directive('profileImage', (Single)->
    (scope, element, attr)->

      meta = Single('meta').get()

      scope.$watch attr.profileImage, (obj)->
        image = if obj then (obj.image or (if obj.profile then (obj.profile.image or obj.profile.pro?.image) else null)) else null
        src = if image then meta.imgbase + image else '/m/assets/img/user.gif'
        attr.$set 'src', src
  )

  .controller( 'MyCtrl', ($scope, $http, Popup, Env, ToggleModal) ->
    console.log 'Myctrl'

    subviews =
      ideabook:
        name: 'ideabook'
        url: 'my/myIdeabooks.tpl.html'
        controller: 'myIdeabooksCtrl'
        cache: yes
        env:
          right: ['新建灵感集']

      bookmark:
        name: 'bookmark'
        url: 'my/myBookmark.tpl.html'
        controller: 'myBookmarkCtrl'

      topic:
        name: 'topic'
        url: 'my/myTopic.tpl.html'
        controller: 'myTopicCtrl'

      upload:
        name: 'upload'
        url: 'my/myUpload.tpl.html'
        controller: 'myUploadCtrl'

    $scope.myView = subviews.ideabook
    $scope.onItem = (item)->
      $scope.myView = subviews[item]

    $scope.$watch 'myView', (view)->
      $scope.env = view?.env

    if not $scope.meta.$resolved
      Popup.loading $scope.meta.$promise

    loadUserData = (user)->
      $scope.user = user
      if user
        user.profile ?= {}
        user.profile.pro ?= {}

      Env.my.right = if user then ['注销'] else ['登录']
      $scope.$emit 'envUpdate'

    $scope.$watch 'meta.user', loadUserData

    $scope.$on '$viewContentLoaded', (e)->
      if e.targetScope is $scope
        $scope.meta.$promise.then -> $scope.isLogin(yes)

    #right button of main bar
    $scope.$on 'rightButton', (e, index)->
      if $scope.isLogin(yes) then $scope.onLogout()

    $scope.onLogout = ->
      $http.post('/auth/logout').then ->
        $scope.meta.user = null


    $scope.onRight = (index)->
      $scope.cacheViewCtrl.scope.$broadcast 'onRight', index

    $scope.onLeft = ()->

    $scope.onMenu = ->
      ToggleModal
        id: 'myMenu'
        template: "<side-pane close-on-resize position='right' class='pane-my-menu popup-in-right'></side-pane>"
        url: "my/myMenu.tpl.html"
        closeOnBackdrop: yes
        scope: $scope
        success: (id)->

    $scope.onEditProfile = ->
      ToggleModal
        id: 'editProfile'
        template: "<modal navable='my/profile.tpl.html' animation='popup-in-right' class='fade-in-out profile-win'></modal>"
        controller: 'myProfileCtrl'
        scope: $scope

    this
  )
  .controller('myIdeabooksCtrl', ($scope, Many, MESSAGE, Popup, Nav)->
    console.log 'myIdeabooksCtrl'

    collection = Many('ideabooks', 'my')

    $scope.objects = []
    $scope.$watch 'user', (user)->
      if user
        $scope.objects = objects = collection.list(author:user.id)
        if not objects.$resolved
          Popup.loading objects.$promise, failMsg:MESSAGE.LOAD_FAILED
        objects.$promise.then (data)->
          $scope.haveMore = objects.meta.more
          $scope.myView.env.left = user.username + "的灵感集(#{data.length})"
          $scope.$broadcast('scroll.reload')

    #Load more objects
    onMore = ->
      if !$scope.haveMore
        $scope.$broadcast('scroll.moreComplete')
      return
      promise = collection.more()
      if promise
        $scope.loadingMore = true
        promise.then( (data)->
          $scope.haveMore = objects.meta.more
        ).finally ->
          $scope.loadingMore = false
          $scope.$broadcast('scroll.moreComplete')

    #Refresh the list
    onRefresh = ()->
      collection.refresh().finally ->
        $scope.$broadcast('scroll.refreshComplete')

    $scope.$on 'scroll.refreshStart', onRefresh
    $scope.$on 'scroll.moreStart', onMore

    $scope.onIdeaBookView = (obj)->
      Nav.go
        name: 'ideabookDetail'
        param: id:obj.id
        push: yes

    $scope.$on 'onRight', ->
      console.log "new ideabook"

    this
  )
  .controller('myProfileCtrl', ($scope, $http, Service, MESSAGE, Popup)->

    $scope.$watch 'user', (user)->
      if not user then return
      $scope.data = angular.copy user
      $scope.profile = $scope.data.profile
      $scope.pro = $scope.profile.pro
      $scope.pro.contact ?= {}

      #Conver some values
      if user.profile.location
        $scope.profile.location= _.find($scope.meta.location, id: user.profile.location)
      $scope.profile.image = null
      if user.profile.pro.category
        $scope.pro.category = _.find($scope.meta.category, id: user.profile.pro.category)

    uploadImage = (id)->
      url = '/api/profile/'+ id
      promise = Service.uploadFile('image', $scope.profile.image, url, 'PATCH')
      promise.then(
        (ret)->
          $scope.profile.image = null
          $scope.user.profile.image = JSON.parse(ret).image
          Popup.alert MESSAGE.UPDATE_OK
          $scope.modal.close()
        (ret)->
          Popup.alert MESSAGE.UPLOAD_FAILED
      )
      promise


    validateMsg =
      email:
        email: MESSAGE.EMAIL_VALID
      required:
        email: MESSAGE.REQ_EMAIL
        address: MESSAGE.REQ_ADDR
        phone: MESSAGE.REQ_PHONE
      url:
        link: MESSAGE.URL_VALID

    validateForms = ->
      if Service.validate($scope.form, validateMsg) and
          (not $scope.formPro or Service.validate($scope.formPro, validateMsg)) and
          (not $scope.formCon or Service.validate($scope.formCon, validateMsg))
        return yes
      return no

    setPristine = ->
      $scope.form.$setPristine()
      $scope.formPro?.$setPristine()
      $scope.formCon?.$setPristine()

    isDirty = ->
      $scope.form.$dirty or $scope.formPro?.$dirty or $scope.formCon?.$dirty or $scope.profile.image

    $scope.onSubmit = ->

      console.log $scope.form, $scope.formPro, $scope.formCon
      console.log $scope.data, $scope.pro, $scope.con

      if Service.noRepeat('updateProfile') and validateForms() and isDirty()

        param = angular.copy($scope.data)
        #Conver some values
        if $scope.profile.location
          param.profile.location = $scope.profile.location.id
        # Set if no profile created
        if not $scope.profile.status
          param.profile.status = 1

        if not $scope.formCon or $scope.formCon.$pristine
          delete param.profile.pro.contact
          if not $scope.formPro or $scope.formPro.$pristine
            delete param.profile.pro

        if param.profile.pro?.category
          param.profile.pro.category = param.profile.pro.category.id

        promise = $http.post('/auth/update', param).then(
          (ret)->
            user = ret.data.user
            $scope.meta.user = user
            setPristine()
            if $scope.profile.image
              # Retrur a chained promise
              return uploadImage(user.profile.id)
            else
              Popup.alert MESSAGE.UPDATE_OK
              $scope.modal.close()
              null
          (ret)->
            console.log ret
            #django backend use diffrent email validation strategy with angular
            msg = if ret.data.error?.email then MESSAGE.EMAIL_VALID else MESSAGE.SUBMIT_FAILED
            Popup.alert msg
            null
        )
        Popup.loading promise, showWin:yes

    this
  )
  .controller('myBookmarkCtrl', ($scope)->
    this
  )
  .controller('myTopicCtrl', ($scope)->
    this
  )
  .controller('myUploadCtrl', ($scope)->
    this
  )