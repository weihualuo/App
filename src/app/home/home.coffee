angular.module('app.home', ['Gallery', 'restangular'])

  .factory('ImageUtil', (Single)->

    imageTable =
      1: [2048, 1536, 1.33]
      2: [1280, 800,  1.6]
      5: [1024, 768,  1.33]
      6: [960, 640,   1.5]
      7: [960, 540,   1.78]
      8: [800, 480,   1.67]
      10: [480, 320,  1.5]

    thumbTable =
      17: [188, 188]
      18: [175, 175]
      19: [155, 155]
      20: [105, 105]
      
    productThumbTable =
      16: [310, 247]
      17: [262, 209]
      18: [236, 188]
      20: [105, 105]

    getThumbWidth = (width, n, r)->
      n ?= 6
      r ?=0.98
      if width <= 1024 then n--
      if width <= 800 then n--
      if width <= 630 then n--
      if width <= 420 then n--

      if width >= 850 then width -= 60
      width -= 4
      width/n*r

    #Get the index most close to width
    getThumbIndex = (width, table)->
      console.log width
      seq = 0
      match = 3000
      for i, v of table
        dif = Math.abs(v[0]-width)
        if dif < match
          match = dif
          seq = i
      seq

    #Return a array in preferred order
    getBestIndexs = (w, h)->
      weight = {}
      ret = []
      index = 0
      r = Number((w/h).toFixed(2))
      for i, v of imageTable
        if w is v[0] and h is v[1]
          weight[i] = 0
        else if r is v[2]
          weight[i] = Math.abs(w-v[0])+1
        else
          weight[i] = Math.abs(w-v[0])+2560

        if index is 0
          ret.push(i)
        else
          insertAt = index
          for ii in [0..index-1]
            if weight[ret[ii]] > weight[i]
              insertAt = ii
              break
          ret.splice(insertAt, 0, i)
        index++
      ret


    thumb_index = getThumbIndex(getThumbWidth(window.innerWidth, 6), thumbTable)
    product_thumb_index = getThumbIndex(getThumbWidth(window.innerWidth, 5, 0.96), productThumbTable)

    w = Math.max(window.innerWidth, window.innerHeight)*window.devicePixelRatio
    h = Math.min(window.innerWidth, window.innerHeight)*window.devicePixelRatio
    best_index = getBestIndexs w, h
    console.log best_index, thumb_index

    meta = Single('meta').get()
    reg = new RegExp(/\d+\/(.+?)-\d+\.(\w+)/)

    getPath = (obj, seq)->
      replaceReg = seq + '/$1-' + seq + '.$2'
      meta.imgbase + obj.image.replace(reg, replaceReg)

    utils =
      path: (obj, seq)->
        paths = obj.paths or (obj.paths = [])
        paths[seq] or (paths[seq] = getPath(obj, seq))
      thumb: (obj)-> @path(obj, thumb_index)
      productThumb: (obj)-> @path(obj, product_thumb_index)
      small: (obj)-> @path(obj, 20)
      best: (obj)->
        if not obj.best
          for i in best_index
            if obj.array & (1<<i)
              break
          #landscape image
          if obj.array & 1
            [obj.width, obj.height] = imageTable[i]
          else
            [obj.height, obj.width] = imageTable[i]
          obj.best = @path(obj, i)
        obj.best
  )
  .filter( 'thumbPath',  (ImageUtil)->
    (obj)-> ImageUtil.thumb(obj)
  )
  .directive('listRender', ()->
    (scope)->
      if scope.$last
        scope.$emit 'list.rendered'
        console.log "I am last", scope.obj.id
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
      element.triggerHandler 'dynamic.add'

  )
  .directive('productThumb', (ImageUtil)->

    restrict:'C'
    link: (scope, element)->

      info = angular.element """
                             <div>
                                <span class='title'></span>
                             </div>
                             """

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
          image.src = ImageUtil.productThumb(scope.obj.params[0])
          image.onload = ->
            element.prepend image
      #image.onerror = ->
      #console.log "onerror", scope.obj.id
      element.triggerHandler 'dynamic.add'

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
      #console.log "gallery.slide", index, x
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


