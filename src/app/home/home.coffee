angular.module('app.home', ['Gallery', 'restangular'])

  .config( (RestangularProvider) ->
    RestangularProvider.addElementTransformer 'photos', false, (obj) ->
      obj.paths = []
      reg = new RegExp(/\d+\/(.+?)-\d+\.(\w+)/)
      used = [0, 1, 2, 6]
      for seq in used
        replaceReg = seq + '/$1-' + seq + '.$2'
        obj.paths[seq] = obj.image.replace(reg, replaceReg)
      if !(obj.array & 1)
        if obj.array & 2
          obj.paths[0] = obj.paths[1]
        else
          obj.paths[0] = obj.paths[2]
      obj
  )
  .filter('fullImagePath', (Single)->

    meta = Single('meta').get()
    # Keep filter as simple as possible
    (obj, seq)->
      return meta.imgbase + obj.paths[parseInt seq]
  )


  .controller( 'HomeCtrl', ($scope, $timeout, $filter, Many, Popup, MESSAGE) ->

    console.log 'HomeListCtrl'

    collection = null
    objects = null

    scrollResize = (reset)->
      $scope.scrollView.scrollTo(0,0) if reset
      #Wait for the list render progress completed
      $timeout (->$scope.$broadcast('scroll.resize')), 300

    obj2Links  = (objs)->
      _.map objs, (obj)->
        href: $filter('fullImagePath')(obj, 0)
        title: obj.title

    $scope.$on 'item.changed', (e, item)->

      $scope.title = item.content
      $scope.pos = item.value

      if item.view != 'home' then return

      collection = Many(item.value)

      $scope.objects = objects = collection.list({num:3})

      if !objects.$resolved
        Popup.loading objects.$promise, null, MESSAGE.LOAD_FAILED

      objects.$promise.then ->
        $scope.haveMore = objects.meta.more
        $scope.total = objects.length + $scope.haveMore

    #Load more objects
    $scope.onMore = ->
      if !$scope.haveMore or !collection
        return
      promise = collection.more()
      if promise
        promise.then (data)->
          $scope.haveMore = objects.meta.more


    #Refresh the list
    $scope.onRefresh = ()->
      promise = collection.refresh()
      if promise
        promise.catch(->
          $popup.alert(MESSAGE.LOAD_FAILED)
        ).finally ->
          $scope.$broadcast('scroll.refreshComplete')
          scrollResize()

  )


