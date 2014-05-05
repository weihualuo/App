angular.module('app.home', ['restangular'])
  .controller( 'ListCtrl', ($scope, name, $timeout, $routeParams, Many, Popup, Env, MESSAGE) ->

    console.log 'ListCtrl'

    #name = $route.current.name
    $scope.updateFilters(name, $routeParams)
    #uri = path.match(/\/(\w+)/)[1]
    collection = Many(name)
    objects = null

    reloadObjects = ->
      # Make sure there is a reflow of empty
      # So that $last in ng-repeat works
      $scope.objects = []
      objects = collection.list($routeParams)
      if !objects.$resolved
        Popup.loading objects.$promise, failMsg:MESSAGE.LOAD_FAILED
      objects.$promise.then -> $timeout ->
        $scope.objects = objects
        $scope.haveMore = objects.meta.more
        Env[name].right = [objects.length + $scope.haveMore + '张']
        $scope.$broadcast('scroll.reload')

    #Load more objects
    onMore = ->
      if !$scope.haveMore
        $scope.$broadcast('scroll.moreComplete')
        console.log "no more"
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
      promise = collection.refresh()
      if promise
        promise.catch(->
          #Popup.alert(MESSAGE.LOAD_FAILED)
        ).finally ->
          $scope.$broadcast('scroll.refreshComplete')

    $scope.$on '$scopeUpdate', reloadObjects
    $scope.$on 'scroll.refreshStart', onRefresh
    $scope.$on 'scroll.moreStart', onMore

  )



