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
      best: (obj)-> @path(obj, 2)

  )
  .directive('imageThumb', (ImageUtil)->

    restrict:'C'
    link: (scope, element)->
      image = null
      element.on 'dynamic.remove', ->
        #console.log "dynamic.remove", scope.obj.id
        if image
          image.remove()
          image = null
      element.on 'dynamic.add', ->
        #console.log "dynamic.add", scope.obj.id
        if not image
          image = new Image()
          image.src = ImageUtil.thumb(scope.obj)
          image.onload = ->
            element.append image
          #image.onerror = ->
            #console.log "onerror", scope.obj.id

  )


  .controller( 'PhotoCtrl', ($scope, $controller, $timeout, $filter, Many, Popup, TogglePane, MESSAGE) ->
    console.log 'PhotoCtrl'

    #extend from ListCtrl
    $controller('ListCtrl', $scope:$scope)

    $scope.onImageInfo = (index)->
      TogglePane
        id: 'infoView'
        template: "<side-pane position='left' class='pane-image-info popup-in-left'></side-pane>"
        url: "modal/imageInfo.tpl.html"
        hash: 'info'
        locals:
          image: $scope.objects[index]

    item = null
    $scope.onImageView = (e)->
      #Delegate mode in large list
      item = e.target
      if item.tagName is 'IMG'
        item = item.parentNode
        obj = angular.element(item).scope().obj
        TogglePane
          id: 'imageView'
          template: "<gallery-view></gallery-view>"
          hash: 'gallery'
          backdrop: false
          scope: $scope
          locals:
            index: $scope.objects.indexOf(obj)
            rect:  item.getBoundingClientRect()

    $scope.$on 'gallery.slide', (e, index, x)->
      console.log "gallery.slide", index, x
      item = item.previousElementSibling if x > 0
      item = item.nextElementSibling if x < 0
      if $scope.haveMore and index+6 > $scope.objects.length
        $scope.$emit 'scroll.moreStart'

    $scope.getItemRect = ->
      scroll = $scope.$scroll
      top = scroll.scroller.getValues().top
      itemTop = item.offsetTop
      itemHeight = item.offsetHeight
      containerHeight = scroll.container.clientHeight
      #above
      if top > itemTop
        scroll.scroller.scrollTo(0, itemTop)
      #below
      else if top < itemTop+itemHeight-containerHeight
        scroll.scroller.scrollTo(0, itemTop+itemHeight-containerHeight)

      item.getBoundingClientRect()

  )
  .controller( 'AdviceCtrl', ($scope, $timeout, $filter, Many, Popup, MESSAGE) ->
    console.log 'AdviceCtrl'

  )
  .controller( 'MyCtrl', ($scope, $timeout, $filter, Many, Popup, MESSAGE) ->
    console.log 'Myctrl'

  )


