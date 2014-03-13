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
