angular.module('app.home', ['restangular'])
  .controller( 'ListCtrl', ($scope, name, $timeout, $q, $routeParams, $location, Restangular, Many, Popup, Env, MESSAGE) ->

    ctrl = this
    ctrl.auto = on
    #uri = path.match(/\/(\w+)/)[1]
    collection = objects = null

    @reload = (search=$location.search(), sub=$routeParams)->

      console.log "reload", name, search, sub

      if angular.isObject(sub) and angular.isUndefined(sub.parent)
        $scope.$emit('filter.update', name, search)
      # Make sure there is a reflow of empty
      # So that $last in ng-repeat works
      $scope.objects = []
      #search maybe a promise object
      promise = $q.when(search).then (search)->
        $scope.collection = collection = Many(name, sub)
        objects = collection.list(search)
        #Use timeout to force a reflow of empty objects
        objects.$promise.then -> $timeout ->
          $scope.objects = objects
          $scope.haveMore = objects.meta.more
          Env[name].count = objects.length + $scope.haveMore
          $scope.$broadcast('scroll.reload')

      Popup.loading(promise, failMsg:MESSAGE.LOAD_FAILED)


    #Load more objects
    @more = ->
      if not $scope.haveMore
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
    @refresh = ->
      collection.refresh().finally ->
        $scope.$broadcast('scroll.refreshComplete')

    $scope.$on '$scopeUpdate', -> ctrl.reload() if ctrl.auto
    $scope.$on 'scroll.refreshStart', ctrl.refresh
    $scope.$on 'scroll.moreStart', ctrl.more

    this
  )




