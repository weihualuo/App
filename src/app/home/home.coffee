angular.module('app.home', ['Gallery', 'restangular'])

  .factory('ImageUtil', (Single)->

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

    thumb_index = getIndex cal window.innerWidth
    meta = Single('meta').get()
    reg = new RegExp(/\d+\/(.+?)-\d+\.(\w+)/)

    getPath = (obj, seq)->
      # request large image but there is not
      # set to second large or third large
      if seq is 0 and !(obj.array & 1)
        if (obj.array & 2) then seq = 1 else seq =2
      replaceReg = seq + '/$1-' + seq + '.$2'
      meta.imgbase + obj.image.replace(reg, replaceReg)

    utils =
      path: (obj, seq)->
        paths = obj.paths or (obj.paths = [])
        paths[seq] or (paths[seq] = getPath(obj, seq))
      thumb: (obj)-> @path(obj, thumb_index)

  )
  .directive('imageThumb', (ImageUtil)->

    (scope, element, attr)->

      element.ready ->
        path = ImageUtil.thumb(scope.obj)
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


