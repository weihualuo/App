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
      18: [230, 187]
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
      #console.log width
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
    #console.log best_index, thumb_index

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
      ideabookThumb: (obj)-> @path(obj, 17)
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
  .filter( 'imagePath',  (ImageUtil)->
    (obj)-> ImageUtil.best(obj)
  )
  .directive('listRender', ()->
    (scope)->
      if scope.$last
        scope.$emit 'list.rendered'
        #console.log "I am last", scope.obj.id
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
  .factory('TransUtil', ()->
    api =
      rectTrans: (rect)->
        rect ?=
          left: window.innerWidth/2 - 100
          top: window.innerHeight/2 -100
          width: 200
          height: 200

        offsetX = (rect.left+rect.width/2-window.innerWidth/2).toFixed(2)
        offsetY = (rect.top+rect.height/2-window.innerHeight/2).toFixed(2)
        ratioX = (rect.width/window.innerWidth).toFixed(2)
        ratioY = (rect.height/window.innerHeight).toFixed(2)
        ret =
          transform: "translate3d(#{offsetX}px, #{offsetY}px, 0) scale3d(#{ratioX}, #{ratioY}, 0)"
  )
  .factory('Transitor', (PrefixedStyle, PrefixedEvent)->

    easeIn = 'all 300ms ease-in'
    caller = (func)-> func?()
    api =
      transIn: (element, transitInStyle, options={})->

        raw = element[0]
        transition = options.transition or easeIn
        attached = options.attached

        if angular.isString(transitInStyle)
          element.addClass(transitInStyle) unless attached
        else if angular.isObject(transitInStyle)
          unless attached
            for key, value of transitInStyle
              PrefixedStyle(raw, key, value)
        else
          return caller

        #console.log "Transitor transIn prepare", transitInStyle


        perform = (done)->
          #console.log "perform transIn", transitInStyle
          PrefixedStyle raw, 'transition', transition
          element.data('entering', yes)

          setTimeout (->
            if angular.isString(transitInStyle)
              element.removeClass(transitInStyle)

            else if angular.isObject(transitInStyle)
              for key, value of transitInStyle
                PrefixedStyle raw, key, null

            else
              return done?()

            entering = yes
            transitEnd = (e)->
              if e.target is raw and element.data('entering')
                #console.log "transIn transitEnd", transitInStyle
                element.data('entering', no)
                #Element maybe leaving before entered
                PrefixedStyle(raw, 'transition', null) unless element.data('leaving')
                PrefixedEvent element, "TransitionEnd", transitEnd, off
                done?()
            PrefixedEvent element, "TransitionEnd", transitEnd
          ), 10

      transOut: (element, transitOutStyle, options={})->

        raw = element[0]
        transition = options.transition or easeIn
        attached = options.attached

        if not transitOutStyle then return caller
        #console.log "Transitor transOut", transitOutStyle

        perform = (done)->

          PrefixedStyle raw, 'transition', transition
          element.data('leaving', yes)
          setTimeout (->
            #console.log "perform transOut", transitOutStyle, raw.style['transition']
            if angular.isString(transitOutStyle)
              element.addClass(transitOutStyle)

            else if angular.isObject(transitOutStyle)
              for key, value of transitOutStyle
                PrefixedStyle raw, key, value

            else return done?()

            transitEnd = (e)->
              if e.target is raw and element.data('leaving')
                #console.log "transOut transitEnd", transitOutStyle
                element.data('leaving', no)
                if not attached
                  if angular.isString(transitOutStyle)
                    element.removeClass(transitOutStyle)
                  else if angular.isObject(transitOutStyle)
                    for key, value of transitOutStyle
                      PrefixedStyle raw, key, null

                #Element maybe entering before entered
                PrefixedStyle(raw, 'transition', null) unless element.data('entering')
                PrefixedEvent element, "TransitionEnd", transitEnd, off
                done?()
            PrefixedEvent element, "TransitionEnd", transitEnd

          ), 10
  )

  .directive('transInOut', (Transitor)->

    link:(scope, element, attr, ctrl)->

      ctrl = scope.$controller
      if not ctrl then return

      transIn = ->
        #console.log "transInOut before", scope.$eval(attr.transIn)
        Transitor.transIn(element, scope.$eval(attr.transIn))

      transOut = (done)->
        #console.log "transInOut out", scope.$eval(attr.transOut)
        Transitor.transOut(element, scope.$eval(attr.transOut))(done)

      ctrl.register transIn, transOut

  )
  .directive('aniHide', (Transitor, $parse)->
    #ani-hide="{class: 'from-top', style: 'opacity: 0', flag: 'env.noHeader', transition: 'all 300ms ease-in'}"
    #ani-hide="{class: 'from-top', flag: '!env.filters'}">
    #class and style can not use at same time
    link:(scope, element, attr)->

      options = scope.$eval(attr.aniHide)
      options.attached = yes
      style = options.class or options.style
      flag = $parse(options.flag)
      #Set initial status
      if scope.$eval(flag)
        element.css display: 'none'

      saved = null
      scope.$watch flag, (value, old)->
        if !value is !old then return
        saved = value
        #perform hide
        if value
          #console.log "perform hide", style
          Transitor.transOut(element, style, options)(->
            console.log "hide end", style
            #value maybe changed during transition
            if saved then element.css display: 'none'
          )
        #perform show
        else
          #console.log "perform show", style
          element.css display: null
          Transitor.transIn(element, style, options)(->
            #console.log "show end ", style
          )

  )
