
angular.module('app.ideabook', [])
  .controller( 'IdeabookCtrl', ($scope, $controller, Nav)->
    #extend from ListCtrl
    $controller('ListCtrl', {$scope:$scope, name: 'ideabooks'})

    this

  )
  .controller('addIdeabookCtrl', ($scope, Many, Service, Restangular, Popup, $q)->
    console.log "addIdeabookCtrl"
    #$scope.template = 'modal/addIdeabook.tpl.html'
    # Operation on the collection will cause inconsistent of home list
    # due to listCtrl use cache mechanisam
    #collection = Many('ideabooks')

    $scope.ideabooks = ideabooks = [{id:0, title: '新建灵感集', pieces:[]}]
    $scope.ideabook = ideabooks[0]
    param = author: $scope.user.id
    #Request the list without cache
    list = null
    Restangular.all('ideabooks').withHttpConfig({cache: false}).getList(param).then (data)->
      list = data
      angular.forEach data, (v)->ideabooks.push v

    saveToIdeabook =(ideabook, deferred)->
      console.log "saveToIdeabook", ideabook
      data =
        image: $scope.image.id
        desc: $scope.desc
      ideabook.post('pieces', data).then(
        (d)->
          console.log "sucess", d
          deferred.resolve()
          Popup.alert '保存成功'
          $scope.modal.close()
        ->
          deferred.reject()
      )

    $scope.onSave = ->
      if not Service.noRepeat('saveIdeabook') then return

      ideabook = $scope.ideabook
      id = $scope.image.id
      for p in ideabook.pieces
        if p.image.id is id
          return Popup.alert '该照片已在此灵感集中'

      deferred = $q.defer()
      Popup.loading deferred.promise
      #Create a new ideabook
      if ideabook.id is 0
        list.post(title:$scope.title).then ((ret)->saveToIdeabook(ret, deferred)), (->deferred.reject())
      else
        saveToIdeabook(ideabook, deferred)
  )