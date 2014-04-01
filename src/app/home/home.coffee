angular.module('app.home', ['Gallery', 'restangular'])

  .config( (RestangularProvider) ->
    RestangularProvider.addElementTransformer 'photos', false, (obj) ->
      obj.paths = []
      reg = new RegExp(/\d+\/(.+?)-\d+\.(\w+)/)
      used = [0, 1, 2, 3, 4, 5, 6]
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
  .directive('imagePath', ($filter, $timeout)->

    imageTable = 3:188, 4:175, 5:155, 6:105
    cal = (wid)->
      n = 6
      if wid <= 1024 then n = 5
      if wid <= 800 then n = 4
      if wid <= 630 then n = 3
      if wid <= 420 then n = 2
      if wid >= 850 then wid -= 60
      wid -= 4
      wid/n*0.98

    getIndex = (wid)->
      console.log wid
      seq = 0
      match = 2000
      for s, w of imageTable
        dif = Math.abs(w-wid)
        if dif < match
          match = dif
          seq = s
      seq

    index = getIndex cal window.innerWidth
    console.log index, imageTable[index]

    (scope, element, attr)->

      element.ready ->
        path = $filter('fullImagePath')(scope.obj, index)
        attr.$set 'src', path

      element.on 'error', ->
        element.off 'error'
        attr.$set 'src', "/m/assets/img/default.jpeg"
  )


  .controller( 'PhotoCtrl', ($scope, $controller, $timeout, $filter, Many, Popup, TogglePane, MESSAGE) ->
    console.log 'PhotoCtrl'

    #extend from ListCtrl
    $controller('ListCtrl', $scope:$scope)

    obj2Links  = (objs)->
      _.map objs, (obj)->
        href: $filter('fullImagePath')(obj, 0)
        title: obj.title

    $scope.onImageInfo = (index)->
      TogglePane
        id: 'infoView'
        template: "<side-pane position='left' class='pane-image-info popup-in-left'></side-pane>"
        url: "modal/imageInfo.tpl.html"
        hash: 'info'
        locals:
          image: $scope.objects[index]

    $scope.onImageView = (obj)->
      TogglePane
        id: 'imageView'
        template: "<gallery-view></gallery-view>"
        url: "modal/gallery.tpl.html"
        hash: 'gallery'
        backdrop: false
        scope: $scope
        locals:
          index: $scope.objects.indexOf(obj)

  )
  .controller( 'AdviceCtrl', ($scope, $timeout, $filter, Many, Popup, MESSAGE) ->
    console.log 'AdviceCtrl'

  )
  .controller( 'MyCtrl', ($scope, $timeout, $filter, Many, Popup, MESSAGE) ->
    console.log 'Myctrl'

  )


