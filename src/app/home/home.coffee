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


  .controller( 'PhotoCtrl', ($scope, $timeout, $filter, Many, Popup, MESSAGE) ->
    console.log 'PhotoCtrl'

    obj2Links  = (objs)->
      _.map objs, (obj)->
        href: $filter('fullImagePath')(obj, 0)
        title: obj.title

    $scope.onImageView = (obj)->
      if $scope.imageView
        $scope.imageView.end()
        $scope.imageView = null
      else
        locals =
          index: $scope.objects.indexOf(obj)
          links: obj2Links($scope.objects)

        template = "<gallery-view on-hide='$close()'></gallery-view>"
        $scope.imageView = Popup.modal "modal/gallery.tpl.html", locals, template, 'gallery'
        $scope.imageView.promise.then().finally -> $scope.imageView = null

  )
  .controller( 'AdviceCtrl', ($scope, $timeout, $filter, Many, Popup, MESSAGE) ->
    console.log 'AdviceCtrl'

  )
  .controller( 'MyCtrl', ($scope, $timeout, $filter, Many, Popup, MESSAGE) ->
    console.log 'Myctrl'

  )


