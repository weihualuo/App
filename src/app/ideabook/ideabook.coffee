
angular.module('app.ideabook', [])

  .directive('ideabookThumb', (ImageUtil)->

    restrict:'C'
    link: (scope, element, attr)->
      image = null
      index = parseInt(attr.index)
      pieces = scope.obj.pieces
      if index >=  pieces.length then return
      obj = pieces[index].image

      element.on 'dynamic.remove', ->
        #console.log "dynamic.remove", scope.obj.id
        if image
          image.remove()
          image = null
      element.on 'dynamic.add', ->
        #console.log "dynamic.add", scope.obj.id
        image = new Image()
        image.src = ImageUtil.ideabookThumb(obj)
        image.onload = ->
          element.prepend image
      #image.onerror = ->
      #console.log "onerror", scope.obj.id
      element.triggerHandler 'dynamic.add'

  )
  .controller( 'IdeabookCtrl', ($scope, $controller, Nav)->
    #extend from ListCtrl
    $scope.listCtrl = $controller('ListCtrl', {$scope:$scope, name: 'ideabooks'})

    $scope.onIdeaBookView = (obj)->
      Nav.go
        name: 'ideabookDetail'
        param: id:obj.id
        push: yes


    this

  )
  .controller('IdeabookDetailCtrl', ($scope, $routeParams, Many, Nav, Popup)->

    console.log 'IdeabookDetailCtrl'
    # Init locals
    collection = Many('ideabooks')
    obj = null

    $scope.$on '$scopeUpdate', ->
      $scope.obj = obj = collection.get parseInt($routeParams.id)
      if not obj.$resolved
        #Loading will end automatically when promise resolved or rejected
        Popup.loading obj.$promise
      #reset the tab state
      obj.$promise.then ->
        console.log "loaded", obj


    $scope.onBack = ->
      Nav.back({name:'ideabooks'})

    this
  )
  .controller('addIdeabookCtrl', ($scope, Many, Service, Restangular, Popup, $q, MESSAGE)->
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
      Popup.loading deferred.promise, showWin:yes

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

    this
  )