angular.module( 'Model', ['restangular'])

  .config( (RestangularProvider) ->

    RestangularProvider.setBaseUrl '/api/'
    RestangularProvider.setDefaultHttpFields({cache: true, timeout: 10000})
#    RestangularProvider.setRequestSuffix '/'
    RestangularProvider.setResponseExtractor (response, operation, what, url)->
      if operation is 'getList' and !(response instanceof Array)
        res = response.results
        res.meta= response.meta
      else
        res = response
      res
#    RestangularProvider.addElementTransformer 'photos', (obj) ->
#      obj
  )

  .factory('Many', (Restangular, $timeout)->
    _objects = {}
    flag = 0
    Factory = (name)->
      #make objects to be a Array and an restangular object
      @name = name
      @cursor = null
      @param = null
      @rest = Restangular.all @name
      this

    Factory.prototype.list = (param, cache=true)->
      if !angular.equals @param, param
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
          @objects.unshift data
      promise

    Factory.prototype.get = (id, force)->
      #If the request id is not the last one, reset cursor
      if !@cursor or @cursor.id isnt id
        @cursor = _.find(@objects, id:Number id) or Restangular.one @name, id
      #If the object is loaded or not
      if !@cursor.$promise or force

        @cursor.$promise = promise =  @cursor.get()
        promise.then( (data)=>
          # bug: restAngular url is not correct
          data.$promise = promise
          angular.copy data, @cursor
          @cursor.$resolved = yes
        ).finally =>

      @cursor

    (name, sub='')->  _objects[name+sub] ?=  new Factory name

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


