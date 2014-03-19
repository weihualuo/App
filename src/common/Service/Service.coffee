angular.module( 'Service', [])

.factory('Service', ($q, $timeout)->

  _objs={}
  Service =
    noRepeat : (name, time=2000)->
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

    Nav =
      push: (view)-> viewStack.push view
      pop: -> viewStack.pop()
      set: (view)-> current = view

      go: (name, param, search, hash)->
        route = _.find $route.routes, name:name
        replace = no
        if route

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


