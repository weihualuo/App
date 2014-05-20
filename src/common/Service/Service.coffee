angular.module( 'Service', [])

.factory('Service', ($q, $timeout, Popup, $browser, Url)->

  _objs={}

  Service =
    noRepeat : (name, time=1000)->
      _objs[name] ?= false
      if _objs[name]
        false
      else
        $timeout (-> _objs[name] = false), time
        _objs[name] = true

    uploadFile : (data, url, method='POST')->
      deferred = $q.defer()
      xhr = new XMLHttpRequest()
      formData = new FormData()
      for key, value of data
        formData.append(key, value)
      formData.append('fuid', new Date().valueOf())
      #Open the AJAX call
      xhr.open(method, Url.U(url), true)

      if window.SERVER
        csrfToken = localStorage.csrf
      else
        csrfToken = $browser.cookies()['csrftoken']
      if csrfToken
        xhr.setRequestHeader('X-CSRFToken', csrfToken)

      xhr.upload.onprogress = (e)->
        deferred.notify e
      xhr.onreadystatechange = (e)->
        if (this.readyState is 4)
          #created
          if this.status is 200 or this.status is 201
            deferred.resolve this.responseText
          # 504 is sae gateway timeout error, most of the case the file is created
          else if this.status is 504 or this.status is 409
            deferred.reject(yes)
          else
            deferred.reject(no)  #this.responseText

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

    disconnectScope : (scope)->
      parent = scope.$parent
      if (parent.$$childHead is scope)
        parent.$$childHead = scope.$$nextSibling
      
      if (parent.$$childTail is scope)
        parent.$$childTail = scope.$$prevSibling
      
      if (scope.$$prevSibling)
        scope.$$prevSibling.$$nextSibling = scope.$$nextSibling
      
      if (scope.$$nextSibling)
        scope.$$nextSibling.$$prevSibling = scope.$$prevSibling
      
      scope.$$nextSibling = scope.$$prevSibling = null

    reconnectScope: (scope)->
      child = scope
      parent = child.$parent
      child.$$prevSibling = parent.$$childTail
      if (parent.$$childHead)
        parent.$$childTail.$$nextSibling = child
        parent.$$childTail = child
      else
        parent.$$childHead = parent.$$childTail = child

    inheritScope : (child, parent)->
      @disconnectScope(child)
      child.$parent = parent
      child.__proto__ = parent
      @reconnectScope(child)

    validate: (form, msgs)->
      if form.$invalid
        for error, inputs of form.$error
          try
            if msg =  msgs[error][inputs[0].$name]
              Popup.alert msg
              break
          catch error
            continue
        return false
      return true
  )
  .factory('PrefixedEvent', ->
    pfx = ["webkit", "moz", "MS", "o", ""]
    ($element, type, callback, isOn=on)->
      for p in pfx
        type = type.toLowerCase() if !p
        if isOn
          $element.on(p+type, callback)
        else
          $element.off(p+type, callback)
  )
  .factory('PrefixedStyle', ->
    pfx = ["-webkit-", "-moz-", "o", ""]
    (element, type, value)->
      for p in pfx
        element.style[p+type]= value
  )
  .factory('Swipe', ($swipe)->

    (element, options)->

      direction = options.direction
      switch direction
        when 'right' then direction = 1
        when 'left' then direction = -1
        else direction = 0

      margin = options.margin or 0
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
          x = 0
          if Math.abs(pos)*2 > width or swiping
            if pos*direction >= 0
              if pos < 0 then x = -width else x = width

          ratio = Number (Math.abs(pos-x)/width).toFixed(2)
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
          # Do not use this corrd, x maybe far out of range when swiping
          # x = coords.x - startX
          gap = event.timeStamp - startTime
          swiping = if gap < 200 then true else false
          onShiftEnd(x, swiping)

        'move': (coords)->
          if disabled then return
          x = coords.x - startX
          if (direction is -1 and x > margin) or
              (direction is 1 and x < -margin)
            x = direction * margin
          else
            if !moving
              moving = true
              onStart(x)
            onMove(x)

      return{
        setDisable: (value)->
          disabled = value
        setDirection: (value)->
          switch value
            when 'right' then direction = 1
            when 'left' then direction = -1
            else direction = 0
        }


  )


