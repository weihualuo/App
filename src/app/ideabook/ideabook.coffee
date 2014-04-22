
angular.module('app.ideabook', [])
  .controller( 'IdeabookCtrl', ($scope, $controller, Nav)->
    #extend from ListCtrl
    $controller('ListCtrl', {$scope:$scope, name: 'ideabooks'})

    this

  )
  .controller('addIdeabookCtrl', ($scope, Many)->
    console.log "addIdeabookCtrl"
    #$scope.template = 'modal/addIdeabook.tpl.html'

    collection = Many('ideabooks')
    $scope.ideabooks = ideabooks = [{id:0, title: '新建灵感集'}]
    $scope.ideabook = ideabooks[0]
#    collection.list(author: $scope.user.id).$promise.then (data)->
#      angular.forEach data, (v)->ideabooks.push v
  )