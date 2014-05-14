angular.module( 'Model', ['restangular'])

  .config( (RestangularProvider) ->

    resolved = ['advices', 'ideabooks']

    RestangularProvider.setBaseUrl '/api/'
    RestangularProvider.setDefaultHttpFields({cache: true, timeout: 10000})
#    RestangularProvider.setRequestSuffix '/'
    RestangularProvider.setResponseExtractor (response, operation, what, url)->
      if operation is 'getList' and !(response instanceof Array)
        res = response.results
        res.meta= response.meta
        if what in resolved
          for data in response.results
            data.$resolved = yes
      else
        res = response
      res
#    RestangularProvider.addElementTransformer 'photos', (obj) ->
#      obj
  )

  .factory('Many', (Restangular)->
    window.rest = Restangular
    _objects = {}
    Factory = (name, sub)->
      #make objects to be a Array and an restangular object
      @name = name
      @cursor = null
      @param = null
      if sub and sub.parent and sub.pid
        base = Restangular.all(sub.parent).one(sub.pid)
      else
        base = Restangular
      @rest = base.all @name
      this

    Factory.prototype.list = (param, cache=true)->
      if not angular.equals(@param, param) or not @objects?.$resolved
        objs = @objects = _.extend [], @rest
        @param = angular.copy param
        #resolved should be reset because collection will be different
        objs.$resolved = no
        objs.$promise = objs.withHttpConfig({cache: cache}).getList(param)
        objs.$promise.then( (data)=>
          objs.meta = data.meta
          #if data is array, it  only copy array
          angular.copy(data, objs)
          objs.$resolved = yes
        )

      #Return the colletion
      @objects

    Factory.prototype.more = ->
      objs = @objects
      #Only perform a more action if there is item loaded
      if objs.length
        param = last:objs[objs.length-1].id
        angular.extend param, @param
        promise = objs.getList(param)
        promise.then (data)=>
          objs.meta = data.meta
          angular.forEach data, (v)->objs.push v
      promise

    Factory.prototype.refresh = ->
      objs = @objects
      #Only perform a refresh is list requested before
      if objs.$resolved
        param = if objs.length then first:objs[0].id else {}
        #disable cache
        angular.extend param, @param
        promise = objs.withHttpConfig({cache: false}).getList(param)
        promise.then (data)=>
          objs.meta = data.meta
          angular.forEach data, (v,i)->objs.splice i,0,v
      promise

      #Should set to @cursor if create successfuls
    Factory.prototype.new = (param, prepend)->
      promise = @rest.post(param)
      if prepend
        promise.then (data)=>
          @objects.unshift(data) if @objects
      promise

    Factory.prototype.get = (id, force)->
      #If the request id is not the last one, reset cursor
      if !@cursor or @cursor.id isnt id
        @cursor = _.find(@objects, id:parseInt(id)) or {}

      #If the object is loaded or not
      if not @cursor.$resolved or force

        @cursor.$promise = promise =  @rest.get(id)
        promise.then( (data)=>
          # bug: restAngular url is not correct
          data.$promise = promise
          angular.copy data, @cursor
          @cursor.$resolved = yes
        ).finally =>

      @cursor

    (name, sub)->
      if sub?.parent
        id = sub.parent + sub.pid + name
      else if angular.isString sub
        id = name + sub
      else
        id = name
      _objects[id] ?=  new Factory name, sub

  )
  #Single factory guaranteed only one object is created for the same identifier
  #No matter how many times the request is sent
  .factory('Single', (Restangular)->
    _objects = {}

    Factory = (name, @default)->
      @value = Restangular.one name
      this

    Factory.prototype.get = (force)->
      if !@value.$promise or force
        @value.$promise = promise = @value.get()
        local = JSON.parse(localStorage.getItem(@value.route)) or @default
        angular.extend(@value, local)
        promise.then( (data)=>
          localStorage.setItem(data.route, JSON.stringify(data))
          data.$promise = promise
          angular.copy data, @value
          @value.$resolved = yes
        ).finally =>

      @value

    # init in only used for the first time
    (name, init)-> _objects[name] ?=  new Factory name, init

  )


