
angular.module('app.edit', [])

  .controller( 'EditCtrl', ($scope, Many, $routeParams, $filter, Service, $timeout, Popup, MESSAGE, Nav)->

    console.log "EditCtrl"
    # Init locals
    id = 0
    d = e = null
    loading = null
    collection = Many('events')

    # Draft save & restore
    # Draft is saved before submit, cleared if submit successful
    # Draft is cleared after restore once
    saveDraft = ->
      localStorage.draftItem = JSON.stringify(d)
    restoreDraft = ->
      draft = localStorage.draftItem
      if draft
        angular.extend(d, JSON.parse draft)
        $timeout -> $scope.form.$setDirty()
        clearDraft()
    clearDraft = ->
      delete localStorage.draftItem

    #first time or object changed
    $scope.$on '$scopeUpdate', ->
      #If id is 0, it is a new event
      id = Number $routeParams.id
      $scope.isNew = if id then 0 else 1
      $scope.d = d = {}
      #form directive is not compile every time in ng-cachingview
      #Should set pristine on entry, form is not ready until all ctrl run, must set timeout
      $scope.failed = false
      $timeout -> $scope.form.$setPristine()
      if id
        $scope.e = e = collection.get id
        if !e.$resolved
          #Loading will end automatically when promise resolved or rejected
          Popup.loading e.$promise, null, MESSAGE.LOAD_FAILED
        e.$promise.then ->
          d.title = e.title
          d.category = _.find($scope.meta.ca, id: e.category)
          d.start_time = $filter('date')(e.start_time, 'yyyy-MM-ddTHH:mm:ss')
          d.end_time =  $filter('date')(e.end_time, 'yyyy-MM-ddTHH:mm:ss')
          d.avenue = e.avenue
          d.description = e.description
          d.imgsrc = $filter('fullImagePath')(e.image.thumbnail2) or "/m/img/noimage.gif"

      # If new event restore from draft
      else
        d.imgsrc = "/m/img/noimage.gif"
        $scope.e = e = null
        restoreDraft()


#    #first time enter this view
#    update()
#
#    #Re-enter this view
#    $scope.$on '$reconnected', ->
#      #If id is not changed, just do nothing
#      update() if $routeParams.id isnt $scope.$param.id

    #Hack on android webkit bug:
    $scope.onStartDateChange = ->
      z = d.start_time.indexOf('Z')
      d.start_time = d.start_time.slice(0,z) if z > 0

    $scope.onEndDateChange = ->
      z = d.end_time.indexOf('Z')
      d.end_time = d.end_time.slice(0,z) if z > 0

    uploadMainImage = (event)->

      #upload image
      url = event.getRestangularUrl()+'/album?main=true'
      #Return a chain promise
      promise = Service.uploadFile('image', d.image, url)
      promise.then(
        (ret)->
          if ret
            event.image = JSON.parse(ret)
          #sae return a 504 or in case of formuid exsist, force a refresh
          else
            collection.get event.id, true
        null
        (e)->
          if e.lengthComputable
            percent = Math.round((e.loaded / e.total) * 100)
            #console.log percent+"%"
      )
      Popup.loading promise, MESSAGE.UPLOADING, MESSAGE.UPLOAD_FAILED
      promise



    onDone = (ret)->
      $scope.$param = {}
      if $scope.isNew
        clearDraft()
        $scope.e = ret
      else
        _.extend $scope.e, ret
      #Upload image after submit successful
      if d.image
        #TODO show progress
        uploadMainImage($scope.e).finally $scope.exitView
      else
        $scope.exitView()

    $scope.exitView = ->
      if $scope.e
        Nav.go 'DetailCtrl', id: $scope.e.id
      else
        $scope.goHome()

    $scope.onSubmit = ->

      saveDraft() if $scope.isNew

      if Service.noRepeat('edit-submit',2000) and $scope.loginOrPopup()

        #Form in invalid
        if $scope.form.$invalid
          $scope.failed = true
          Popup.alert("红色部分为必填项！")
          return
        #Form unchanged
        if $scope.form.$pristine
          onDone()
          return

        p = {}
        p.title = d.title
        p.category = d.category.id
        p.avenue = d.avenue
        p.description = d.description

        #Convert to timezone format first
        startTime = new Date $filter('date')(d.start_time, 'yyyy-MM-ddTHH:mm:ssZ')
        p.start_time = startTime.toISOString()
        if d.end_time
          endTime = new Date $filter('date')(d.end_time, 'yyyy-MM-ddTHH:mm:ssZ')
          p.end_time = endTime.toISOString()

        #Commit to server
        #Patch the existing object
        if id
          promise = $scope.e.patch(p)
        #Create a new object
        else
          promise = collection.new(p)
        promise.then onDone
        #Start loading view
        Popup.loading promise, MESSAGE.SUBMITTING, MESSAGE.SUBMIT_FAILED

  )
