angular.module('app.home', ['Gallery', 'restangular'])

  .config( (RestangularProvider) ->
    RestangularProvider.addElementTransformer 'photos', false, (obj) ->
      obj.paths = []
      reg = new RegExp(/\d+\/(.+?)-\d+\.(\w+)/)
      used = [0, 1, 2, 6]
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

    width = null
    getSeq = (width)-> 6

    (scope, element, attr)->

      element.ready ->
        width ?= element[0].clientWidth
        seq = getSeq(width)
        path = $filter('fullImagePath')(scope.obj, seq)
        $timeout (->attr.$set 'src', path), 1000
  )


  .controller( 'PhotoCtrl', ($scope, $timeout, $filter, Many, Popup, TogglePane, MESSAGE) ->
    console.log 'PhotoCtrl'

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
        locals:
          index: $scope.objects.indexOf(obj)
          links: obj2Links($scope.objects)
          onImageInfo: $scope.onImageInfo

  )
  .controller( 'AdviceCtrl', ($scope, $timeout, $filter, Many, Popup, MESSAGE) ->
    console.log 'AdviceCtrl'

  )
  .controller( 'MyCtrl', ($scope, $timeout, $filter, Many, Popup, MESSAGE) ->
    console.log 'Myctrl'

  )


