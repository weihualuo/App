angular.module('app.detail.image', [])
  .controller( 'ImageSlideCtrl', ($scope, Many, $routeParams)->

    collection = Many('events')

    #first time or object changed
    $scope.$on '$scopeUpdate', ->
      e = collection.get Number $routeParams.id
      $scope.images = e.album
  )
  .controller( 'ImageUploadCtrl', ($scope, Many, $routeParams, Service, MESSAGE)->

    collection = Many('events')

    #first time or object changed
    $scope.$on '$scopeUpdate', ->
      console.log "image upload ctrl update"
      $scope.e = collection.get Number $routeParams.id
      $scope.files = []

    uploadImage = (file, event)->
      #upload image
      url = event.getRestangularUrl()+'/album'
      #Return a chain promise
      Service.uploadFile('image', file, url).then(
        (ret)->
          file.progress = null
          if ret
            event.album.push JSON.parse(ret)
          #sae return a 504 or in case of formuid exsist, force a refresh
          else
            event.getList('album').then (d)->
              event.album = d
        ()->
          file.error = MESSAGE.UPLOAD_FAILED
          file.progress = '0%'
        (e)->
          if e.lengthComputable
            percent = Math.round((e.loaded / e.total) * 100)
            file.progress =  percent+"%"
      )

    $scope.onSelect = (file)->
      #Insert file at the front
      $scope.files.push file
      Service.readFile(file).then(
        (data)->
          file.preview = data
          file.progress = '0%'
          uploadImage(file, $scope.e)
        ()-> file.error = MESSAGE.LOAD_FAILED
      )

  )