angular.module('app.home', ['restangular'])
  .controller( 'ListCtrl', ($scope, name, $timeout, $routeParams, Many, Popup, Env, MESSAGE) ->

    console.log 'ListCtrl'

    #name = $route.current.name
    $scope.updateFilters(name, $routeParams)
    #uri = path.match(/\/(\w+)/)[1]
    $scope.collection = collection = Many(name)
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
        Env[name].count = objects.length + $scope.haveMore
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
        promise.then( ->
          $scope.haveMore = objects.meta.more
        ).finally ->
          $scope.loadingMore = false
          $scope.$broadcast('scroll.moreComplete')

    #Refresh the list
    onRefresh = ()->
      collection.refresh().finally ->
        $scope.$broadcast('scroll.refreshComplete')

    $scope.$on '$scopeUpdate', reloadObjects
    $scope.$on 'scroll.refreshStart', onRefresh
    $scope.$on 'scroll.moreStart', onMore

    this
  )
  .controller('MyListCtrl', ($scope, name, Many, MESSAGE, Popup, $timeout)->
    console.log 'MyListCtrl'

    $scope.collection = collection = Many(name, 'my')
    objects = null

    reloadObjects = (user)->
      # Make sure there is a reflow of empty
      # So that $last in ng-repeat works
      $scope.objects = []
      objects = collection.list(author:user.id)
      if !objects.$resolved
        Popup.loading objects.$promise, failMsg:MESSAGE.LOAD_FAILED
      objects.$promise.then -> $timeout ->
        $scope.objects = objects
        $scope.haveMore = objects.meta.more
        $scope.$broadcast('scroll.reload')

    #Load more objects
    onMore = ->
      if !$scope.haveMore
        $scope.$broadcast('scroll.moreComplete')
        return
      promise = collection.more()
      if promise
        $scope.loadingMore = true
        promise.then( ->
          $scope.haveMore = objects.meta.more
        ).finally ->
          $scope.loadingMore = false
          $scope.$broadcast('scroll.moreComplete')

    #Refresh the list
    onRefresh = ()->
      collection.refresh().finally ->
        $scope.$broadcast('scroll.refreshComplete')


    $scope.$watch 'user', reloadObjects
    $scope.$on 'scroll.refreshStart', onRefresh
    $scope.$on 'scroll.moreStart', onMore

    this
  )



