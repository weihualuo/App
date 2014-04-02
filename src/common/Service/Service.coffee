angular.module( 'Service', [])

.factory('Service', ($q, $timeout)->

  _objs={}
  Service =
    noRepeat : (name, time=1000)->
      _objs[name] ?= false
      if _objs[name]
        false
      else
        $timeout (-> _objs[name] = false), time
        _objs[name] = true

    uploadFile : (name, file, url)->
      deferred = $q.defer()
      xhr = new XMLHttpRequest()
      formData = new FormData()
      formData.append(name, file)
      formData.append('formuid', new Date().valueOf())
      #Open the AJAX call
      xhr.open('post', url, true)
      xhr.upload.onprogress = (e)->
        deferred.notify e
      xhr.onreadystatechange = (e)->
        if (this.readyState is 4)
          #created
          if this.status is 201
            deferred.resolve this.responseText
          # 504 is sae gateway timeout error, most of the case the file is created
          else if this.status is 504
            deferred.resolve()
          else
            deferred.reject  this.responseText

      xhr.send(formData)
      #Return a promise
      deferred.promise


    readFile : (file)->
      deferred = $q.defer()
      reader = new FileReader()
      reader.onload = (e)->
        deferred.resolve e.target.result
      reader.onerror = ->
        deferred.reject()

      #read data take a while on mp
      reader.readAsDataURL(file)
      #Return a promise
      deferred.promise


  )
  .factory('Nav', ($route, $location)->

    viewStack = []
    current = null
    currentName = null

    Nav =
      push: (view)-> viewStack.push view
      pop: -> viewStack.pop()
      set: (view)-> current = view

      go: (name, param, search, hash)->
        name ?= currentName
        route = _.find $route.routes, name:name
        replace = no
        if route
          currentName = name
          oldIndex = if current then current.data('$zIndex') or 0 else 0
          newIndex = route.zIndex
          #Not a forward navigation
          if newIndex <= oldIndex
            last = viewStack[viewStack.length-1]
            #Already in the viewstack
            if last and last.data('$templateUrl') is route.templateUrl
              history.back()
              return
              #Should replace the current view
            else
              replace = yes


          #View is not in stack
          path = route.originalPath
          _.each param, (value, key)->
            re = new RegExp(':'+key)
            path = path.replace(re, value)

          $location.replace() if replace
          $location.path path
          $location.search search or {}
          $location.hash hash or null
  )
  .factory('PrefixedEvent', ->
    pfx = ["webkit", "moz", "MS", "o", ""]
    ($element, type, callback)->
      for p in pfx
        type = type.toLowerCase() if !p
        $element.on(p+type, callback)
  )
  .factory('PrefixedStyle', ->
    pfx = ["-webkit-", "-moz-", "o", ""]
    (element, type, value)->
      for p in pfx
        element.style[p+type]= value
  )
  .factory('Swipe', ($swipe, PrefixedStyle, PrefixedEvent)->

    (element, position, onHide)->

      startTime = 0
      startX = 0
      x = 0
      pane = element[0]
      moving = false
      snaping = false

      PrefixedEvent element, "TransitionEnd", ->
        if snaping
          snaping = false
          if x is 0
            setAnimate(null)
          else
            setAnimate('none')
            onHide() if onHide


      updatePosition = (offset)->
        if offset
          PrefixedStyle pane, 'transform', "translate3d(#{offset}px, 0, 0)"
        else
          PrefixedStyle pane, 'transform', null
      setAnimate = (prop)->
        PrefixedStyle pane, 'transition', prop

      onShiftEnd = (swiping)->
        if moving
          moving = false
          width = pane.offsetWidth
          pos = x
          time = Math.abs(x)/width * 0.3
          if Math.abs(x)*2 > width or swiping
            if x < 0 then x = -width else x = width
          else
            x = 0
          if x isnt pos
            snaping = true
            setAnimate "all "+time.toFixed(2)+"s ease-in"
            updatePosition(x)
          else if x isnt 0
            setAnimate('none')
            onHide() if onHide

      $swipe.bind element,
        'start': (coords, event)->
          startX = coords.x - x
          startTime = event.timeStamp

        'cancel': ->
          onShiftEnd()
        'end': (cor, event)->
          onShiftEnd()

        'move': (coords, event)->
          if snaping then return
          x = coords.x - startX
          if (position == 'left' and x > 0) or
              (position == 'right' and x < 0)
            x = 0
          else
            if !moving
              moving = true
              gap = event.timeStamp - startTime
              console.log gap
              if gap < 100
                onShiftEnd(true)
                return
              setAnimate(null)
            updatePosition(x)


  )


