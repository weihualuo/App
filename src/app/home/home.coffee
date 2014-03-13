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

    obj2Links  = (objs)->
      _.map objs, (obj)->
        href: $filter('fullImagePath')(obj, 0)
        title: obj.title


    collection = Many('photos')

    objects = null
    $scope.imageLinks = null
    $scope.imageLinksMore = null
    $scope.objects = objects = collection.list({num:3})

    if !objects.$resolved
      Popup.loading objects.$promise, null, MESSAGE.LOAD_FAILED

    objects.$promise.then ->
#      $scope.imageLinks = obj2Links objects
      $scope.haveMore = objects.meta.more

    #Load more objects
    $scope.onMore = ->
      if !$scope.haveMore
        return
      promise = collection.more()
      if promise
        promise.then (data)->
#          $scope.imageLinksMore = obj2Links data
          $scope.haveMore = objects.meta.more

  )


