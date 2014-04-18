angular.module('app.utils', [])

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
      last: (obj)-> @path(obj, 10)
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
  .directive('noWatch', ($parse)->
    (scope, element, attr)->
      parsed = $parse(attr.noWatch)
      value = (parsed(scope) || '').toString()
      element.text(value)
      attr.$set('noWatch', null)
  )
  .directive('include', ($http, $templateCache, $compile)->
    (scope, element, attr) ->
      $http.get(attr.include, cache: $templateCache).success (content)->
        element.html(content)
        $compile(element.contents())(scope)
  )
  .directive('listFilter', ()->
    restrict: 'E'
    replace: true
    template: """
              <a class="filter-menu res-display-l" ng-click="toggleFilter(filter)">
                {{item.cn || item.en}} <i class="icon ion-arrow-down-b"></i>
              </a>
              """
    link: (scope, element) ->
      #Should use with ng-repeat
      scope.$watch 'paramUpdateFlag', ->
        scope.item = scope.getFilterItem(scope.filter)
        if scope.item.id
          element.addClass 'active'
        else
          element.removeClass 'active'
  )
  .factory('TransUtil', ()->
    api =
      rectTrans: (rect)->
        rect ?=
          left: window.innerWidth/2 - 100
          top: window.innerHeight/2 -100
          width: 200
          height: 200

        offsetX = rect.left+rect.width/2-window.innerWidth/2
        offsetY = rect.top+rect.height/2-window.innerHeight/2
        ratioX = rect.width/window.innerWidth
        ratioY = rect.height/window.innerHeight
        ret =
          transform: "translate3d(#{offsetX}px, #{offsetY}px, 0) scale3d(#{ratioX}, #{ratioY}, 0)"
  )
  .directive('rectTrans', (PrefixedStyle, PrefixedEvent)->

    setTransform = (el, rect)->
      offsetX = rect.left+rect.width/2-window.innerWidth/2
      offsetY = rect.top+rect.height/2-window.innerHeight/2
      ratioX = rect.width/window.innerWidth
      ratioY = rect.height/window.innerHeight
      PrefixedStyle el, 'transform', "translate3d(#{offsetX}px, #{offsetY}px, 0) scale3d(#{ratioX}, #{ratioY}, 0)"

    (scope, element, attr)->
      raw = element[0]
      if rect = scope[attr.rectTrans]
        setTransform raw, rect
        element.ready ->
          PrefixedStyle raw, 'transition', 'all 300ms ease-in'
          PrefixedStyle raw, 'transform', null

      scope.transformer =  (rect, callback)->
        rect ?=
          left: window.innerWidth/2 - 100
          top: window.innerHeight/2 -100
          width: 200
          height: 200

        PrefixedStyle raw, 'transition', 'all ease-in 300ms'
        #TODO must use a timeout, why?
        setTimeout (->setTransform raw, rect), 10
        PrefixedEvent element, "TransitionEnd", ->
          console.log "end"
          PrefixedStyle raw, 'transition', null
          callback?()
  )
  .directive('transInOut', (PrefixedStyle, PrefixedEvent)->
    (scope, element, attr)->
      transitInStyle = transitOutStyle = null
      transition = attr.transInOut or 'all 300ms ease-in'
      raw = element[0]
      entering = no
      leaving = no

      scope.transformer =

        transBefore: ->
          transitInStyle = scope.$eval(attr.transIn)
          if not transitInStyle then return
          entering = yes
          if angular.isString(transitInStyle)
            element.addClass(transitInStyle)
          else if angular.isObject(transitInStyle)
            for key, value of transitInStyle
              PrefixedStyle raw, key, value
          PrefixedStyle raw, 'transition', transition


        transIn: ->
          if not transitInStyle then return
          setTimeout (->
            if angular.isString(transitInStyle)
              element.removeClass(transitInStyle)

            else if angular.isObject(transitInStyle)
              for key, value of transitInStyle
                PrefixedStyle raw, key, null

            transitEnd = (e)->
              if e.target is raw and entering
                entering = no
                PrefixedStyle raw, 'transition', null
                PrefixedEvent element, "TransitionEnd", transitEnd, off
            PrefixedEvent element, "TransitionEnd", transitEnd
            ), 10

        transOut: (done)->
          transitOutStyle = scope.$eval(attr.transOut)
          if not transitOutStyle then return done()

          leaving = yes
          PrefixedStyle raw, 'transition', transition
          if angular.isString(transitOutStyle)
            setTimeout (->element.addClass(transitOutStyle)), 10

          else if angular.isObject(transitOutStyle)
            for key, value of transitOutStyle
              PrefixedStyle raw, key, value

          transitEnd = (e)->
            if e.target is raw and leaving
              leaving = no

              if angular.isString(transitOutStyle)
                element.removeClass(transitOutStyle)
              else if angular.isObject(transitOutStyle)
                for key, value of transitOutStyle
                  PrefixedStyle raw, key, null

              PrefixedStyle raw, 'transition', null
              PrefixedEvent element, "TransitionEnd", transitEnd, off
              done()

          PrefixedEvent element, "TransitionEnd", transitEnd
  )
  .factory('Tansformer', ($timeout, PrefixedStyle, PrefixedEvent)->

    api =
      enter: (element, parent, after, transitInStyle, complete)->
        raw = element[0]
        transition = 'all 300ms ease-in'

        if transitInStyle
          element.addClass(transitInStyle)
          PrefixedStyle raw, 'transition', transition

        if after
          after.after(element)
        else
          parent.append(element)

        if transitInStyle

          entering = yes
          transit = ->
            element.removeClass(transitInStyle)
          setTimeout transit, 10

          transitEnd = (e)->
            if e.target is raw and entering
              entering = no
              PrefixedStyle raw, 'transition', null
              PrefixedEvent element, "TransitionEnd", transitEnd, off
              complete?()

          PrefixedEvent element, "TransitionEnd", transitEnd
        else
          complete?()

      leave: (element, transitOutStyle)->
        raw = element[0]
        transition = 'all 300ms ease-in'

        if transitOutStyle

          leaving = yes
          PrefixedStyle raw, 'transition', transition
          transit = ->
            element.addClass(transitOutStyle)
          setTimeout transit, 10

          transitEnd = (e)->
            if e.target is raw and leaving
              leaving = no
              element.removeClass(transitOutStyle)
              PrefixedStyle raw, 'transition', null
              PrefixedEvent element, "TransitionEnd", transitEnd, off
              element.remove()

          PrefixedEvent element, "TransitionEnd", transitEnd

        else
          element.remove()

  )