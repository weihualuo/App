
angular.module('app.ideabook', [])
  .controller( 'IdeabookCtrl', ($scope, $controller, Nav)->
    #extend from ListCtrl
    $controller('ListCtrl', {$scope:$scope, name: 'ideabooks'})

    this

  )
  .controller('addIdeabookCtrl', ($scope, Many, Service, Restangular, Popup, $q, MESSAGE)->
    console.log "addIdeabookCtrl"
    #$scope.template = 'modal/addIdeabook.tpl.html'
    # Operation on the collection will cause inconsistent of home list
    # due to listCtrl use cache mechanisam
    #collection = Many('ideabooks')

    $scope.ideabooks = ideabooks = [{id:0, title: MESSAGE.NEW_IDEABOOK, pieces:[]}]
    $scope.ideabook = ideabooks[0]
    param = author: $scope.user.id
    #Request the list without cache
    list = null
    Restangular.all('ideabooks').withHttpConfig({cache: false}).getList(param).then (data)->
      list = data
      angular.forEach data, (v)->ideabooks.push v

    saveToIdeabook =(ideabook, deferred)->
      data =
        image: $scope.image.id
        desc: $scope.desc
      ideabook.post('pieces', data).then(
        ()->
          deferred.resolve()
          Popup.alert MESSAGE.SAVE_OK
          $scope.modal.close()
        (error)->
          msg = if error.data.image then MESSAGE.IMAGE_EXIST else  MESSAGE.SAVE_NOK
          Popup.alert msg
          deferred.reject()
      )

    $scope.onSave = ->
      if not Service.noRepeat('saveIdeabook') then return

      ideabook = $scope.ideabook
      id = $scope.image.id
      title = $scope.title

      if ideabook.id is 0
        if not title
          return Popup.alert MESSAGE.REQ_TITLE
        else if _.find(ideabooks, title:title)
          return Popup.alert MESSAGE.TITLE_EXIST

      for p in ideabook.pieces
        if p.image.id is id
          return Popup.alert MESSAGE.IMAGE_EXIST

      deferred = $q.defer()
      Popup.loading deferred.promise, failMsg: no

      #Create a new ideabook
      if ideabook.id is 0
        list.post(title:title).then(
          (newObj)-> saveToIdeabook(newObj, deferred)

          (error)->
            msg = if error.data.title then MESSAGE.TITLE_EXIST else  MESSAGE.SAVE_NOK
            Popup.alert msg
            deferred.reject()

        )
      else
        saveToIdeabook(ideabook, deferred)
  )