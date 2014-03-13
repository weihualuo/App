

angular.module( 'Resource', ['ngResource'])

  .config( () ->
  )

  .factory('Collection', ($resource)->

    _objects = {}

    #Colloction Factory
    Factory = (name, actions)->
      Resource = $resource("/api/#{name}/:id/:sub/:subId", {id:"@id", sub:"@$subUri", subId:"@$subId"}, actions)
      collection = null
      cursor = null

      #Getter for Resource
      @Resource = -> Resource

      @list = ->
        #Perform the query only if not loaded
        collection ?= Resource.query()
      @refresh = ->
        if collection and collection.length
          Resource.query first:collection[0].id, (data)->
            angular.forEach data, (value,index)->collection.splice index,0,value
      @more = ->
        if collection and collection.length
          Resource.query last:collection[collection.length-1].id, (data)->
            angular.forEach data, (value)->collection.push value
      @retrieve = (id, refresh)->
        # If the request id is not the last one, reset cursor
        if !cursor or cursor.id isnt id
          cursor = _.find(collection, id:Number id)
        # If the request id is not in colletion, get by Resource
        if !cursor
          cursor = Resource.get id:id, ->
            cursor.$detail = true
        # If force to refresh or detail in not retrieved yes
        else if refresh or !cursor.$detail
          cursor.$resolved = false
          cursor.$promise = cursor.$get ->
            cursor.$detail = true
        #return cursor ??is there a $promise?
        cursor
        
      @create = (data)->
        item = new Resource()
        angular.extend item, data

      @postSub = (id, sub, data)->
        @create( angular.extend(data, {id:id, $subUri: sub})).$save()

      @deleteSub = (id, sub)->
        Resource.delete({id:id, sub:sub}).$promise

      @listSub = (id, sub)->
        Resource.query({id:id, sub:sub})

      @deleteSubItem = (id, sub, subId)->
        Resource.delete({id:id, sub:sub, subId:subId}).$promise

      #Retrun this in coffeescript
      this

    #Create a new colletion or return the exist one
    (name)->  _objects[name] ?=  new Factory name


  )