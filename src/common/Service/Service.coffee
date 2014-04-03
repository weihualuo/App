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

    (element, options)->

      direction = options.direction
      onStart = options.onStart or angular.noop
      onMove = options.onMove or angular.noop
      onEnd = options.onEnd or angular.noop

      startTime = 0
      startX = 0
      x = 0
      moving = false
      disabled = false

      onShiftEnd = (x, swiping)->
        if moving
          moving = false
          pos = x
          width = element[0].offsetWidth
          if Math.abs(x)*2 > width or swiping
            if x < 0 then x = -width else x = width
          else
            x = 0
          ratio = null
          if x isnt pos
            ratio = (Math.abs(pos-x)/width).toFixed(2)
          console.log "pos=#{pos}, x=#{x}, width=#{width}"
          onEnd(x, ratio)

      $swipe.bind element,
        'start': (coords, event)->
          startX = coords.x
          startTime = event.timeStamp

        'cancel': ->
          console.log "cancel"
          onShiftEnd(x)
        'end': (coords, event)->
          if disabled then return
          x = coords.x - startX
          gap = event.timeStamp - startTime
          swiping = if gap < 200 then true else false
          onShiftEnd(x, swiping)

        'move': (coords)->
          if disabled then return
          x = coords.x - startX
          if (direction == 'left' and x > 0) or
              (direction == 'right' and x < 0)
            x = 0
          else
            if !moving
              moving = true
              onStart(x)
            onMove(x)

      return{
        setDisable: (value)->
          disabled = value
        setDirection: (value)->
          direction = value
        }


  )


