

xdescribe 'Resource factory', ->

  objects = [ {"id": 21,"title": "title21"} , {"id": 22,"title": "title22"}]
  objects_new = [ {"id": 11,"title": "title11"} , {"id": 12,"title": "title12"}]
  objects_more = [ {"id": 31,"title": "title31"} , {"id": 32,"title": "title32"}]
  item = id:21, desc: "this is detail information"
  item2 = id:22, desc: "this is detail information 2"
  item_isolate = id: 1, desc: "this is isolated item"

  others = [ {"id": 21,"other": "other21"} , {"id": 22,"other": "other22"}]
  others_new = [ {"id": 11,"other": "other11"} , {"id": 12,"other": "other12"}]
  others_more = [ {"id": 31,"other": "other31"} , {"id": 32,"other": "other32"}]

  meta = key: 'value', user: {id:1, name: "my name"}
  meta2 = key2: 'value2', user2: {id:2, name2: "my name2"}

  beforeEach module 'Resource'

  beforeEach ->
    this.addMatchers
      toEqualData: (expected)->
        angular.equals(this.actual, expected)

  $rootScope = null
  $httpBackend = null
  $timeout = null
  Collection = null

  beforeEach inject (_$httpBackend_, _Collection_,_$rootScope_,_$timeout_)->
    Collection = _Collection_
    $httpBackend = _$httpBackend_
    $rootScope = _$rootScope_
    $timeout = _$timeout_

  afterEach ->
    $rootScope.$apply()
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()

  "
  ii = angular.injector(['app','ng']);
  $resource = ii.get('$resource');
  EventResource = $resource('/api/events/:id/:sub/:subId', {id:'@id'});
  Collection = ii.get('Collection');
  Event = Collection('events');
  events = Event.list();

    CustomResource = $resource('/api/events/:id',{id:'@id'}, {cancel: {method:'POST', url:'/api/events/:id/cancel'} } );
    SubResource = $resource('/api/events/:id/:sub/:subId',{id:'@id'}, {cancel: {method:'POST', url:'/api/events/:id/cancel'} } );
    es = CustomResource.query();
    a = new SubResource();a.id = 114;a.$save({sub:'comments'})
    CommentResource = $resource('/api/events/:eventId/comments/:id',{id:'@id'}) ;

    "
  describe 'Collection factory', ->
    Event = null
    success = jasmine.createSpy 'success'
    fail = jasmine.createSpy 'fail'
    always = jasmine.createSpy 'always'
    beforeEach ->
      Event = Collection('events')
      success = jasmine.createSpy 'success'
      fail = jasmine.createSpy 'fail'
      always = jasmine.createSpy 'always'


    it "Should create a unique collection class with identifier", ->
      Event = Collection('events')
      Event2 = Collection('events')
      Comment = Collection('Comment')
      expect(Event).toEqual(Event2)
      expect(Event).toNotEqual(Comment)
      expect(Event.list).toBeDefined()
      expect(Event.more).toBeDefined()
      expect(Event.refresh).toBeDefined()
      expect(Event.retrieve).toBeDefined()
      expect(Event.create).toBeDefined()

    it "Should return the list with promise on query, only for the first time", ->
      $httpBackend.expectGET('/api/events').respond objects
      #Reqeust the list should return a empty array with $promise
      events = Event.list()
      events.$promise.then(success,fail).finally(always)
      expect(events).toEqualData([])
      expect(events.$resolved).toBeFalsy()

      #Reponse with objects successful
      $rootScope.$apply()
      $httpBackend.flush()
      expect(events).toEqualData(objects)
      expect(events.$resolved).toBeTruthy()
      expect(success).toHaveBeenCalled()
      expect(always).toHaveBeenCalled()
      expect(fail.calls.length).toEqual(0)

      #Should return the same list
      list = Event.list()
      $rootScope.$apply()
      expect(list).toEqual(events)

    it "Should call the failed function if respond a error", ->
      #Response with 404
      $httpBackend.expectGET('/api/events').respond 404
      list = Event.list()
      list.$promise.then(success,fail).finally(always)
      $rootScope.$apply()
      $httpBackend.flush()
      expect(list.$resolved).toBeTruthy()
      expect(fail.calls.length).toEqual(1)

    it "Should append more items to the list after the last and return a promise", ->
      $httpBackend.expectGET('/api/events').respond objects
      #Do nothing if list is not loaded yet
      expect(Event.more()).toBeUndefined()
      events = Event.list()
      $rootScope.$apply()
      $httpBackend.flush()

      #Load more items
      $httpBackend.expectGET('/api/events?last=22').respond objects_more
      Event.more().$promise.then(success,fail).finally(always)
      $rootScope.$apply()
      $httpBackend.flush()
      expect(success.calls.length).toEqual(1)
      #Should append more item to events
      expect(events).toEqualData objects.concat objects_more

    it "Should insert new items to the list before the first and return a promise", ->
      $httpBackend.expectGET('/api/events').respond objects
      #Do nothing if list is not loaded yet
      expect(Event.refresh()).toBeUndefined()
      events = Event.list()
      $rootScope.$apply()
      $httpBackend.flush()

      #Load more items
      $httpBackend.expectGET('/api/events?first=21').respond objects_new
      Event.refresh().$promise.then(success,fail).finally(always)
      $rootScope.$apply()
      $httpBackend.flush()
      expect(success.calls.length).toEqual(1)
      #Should append more item to events
      expect(events).toEqualData objects_new.concat objects


    it 'should fetch item details in the list only on the first visit ', ->
      $httpBackend.expectGET('/api/events').respond objects
      events = Event.list()
      $rootScope.$apply()
      $httpBackend.flush()

      #Retrieve the first item in the list
      $httpBackend.expectGET('/api/events/21').respond item
      event = Event.retrieve 21
      #Should get the list item with a promise
      expect(event).toEqual(events[0])
      event.$promise.then(success,fail).finally(always)
      expect(event.$resolved).toBeFalsy()

      $rootScope.$apply()
      $httpBackend.flush()
      expect(event.$resolved).toBeTruthy()
      expect(success.calls.length).toEqual(1)
      expect(event).toEqualData(item)

      # should get the same object on the later request
      event2 = Event.retrieve 21
      expect(event2.$resolved).toBeTruthy()
      expect(event2).toEqual(event)

    it "should be able fetch item details not in list and only on the first visit", ->
      $httpBackend.expectGET('/api/events').respond objects
      #query the list first
      events = Event.list()
      $rootScope.$apply()
      $httpBackend.flush()

      #Retrieve item isolated
      $httpBackend.expectGET('/api/events/1').respond item_isolate
      event = Event.retrieve 1
      #Should return a object with promise
      event.$promise.then(success,fail).finally(always)
      expect(event.$resolved).toBeFalsy()

      $rootScope.$apply()
      $httpBackend.flush()
      expect(event.$resolved).toBeTruthy()
      expect(success.calls.length).toEqual(1)
      expect(event).toEqualData(item_isolate)

      # should get the same object on the later request
      event2 = Event.retrieve 1
      expect(event2.$resolved).toBeTruthy()
      expect(event2).toEqual(event)

    it "should be able fetch item details without the list and only on the first visit", ->
      $httpBackend.expectGET('/api/events/1').respond item_isolate
      event = Event.retrieve 1
      #Should return a object with promise
      event.$promise.then(success,fail).finally(always)
      expect(event.$resolved).toBeFalsy()

      $rootScope.$apply()
      $httpBackend.flush()
      expect(event.$resolved).toBeTruthy()
      expect(success.calls.length).toEqual(1)
      expect(event).toEqualData(item_isolate)

      # should get the same object on the later request
      event2 = Event.retrieve 1
      expect(event2.$resolved).toBeTruthy()
      expect(event2).toEqual(event)


    it "should alwayse fetch item details by force update",->
      $httpBackend.expectGET('/api/events/21').respond item
      event = Event.retrieve 21
      $rootScope.$apply()
      $httpBackend.flush()

      extra = extra:"extra value", title: "title new"
      $httpBackend.expectGET('/api/events/21').respond extra
      Event.retrieve 21, true
      $rootScope.$apply()
      $httpBackend.flush()
      expect(event).toEqualData(extra)


    it 'should be able to serve for multiple collections at the same time ', ->
      #Query for  two list at the same time
      $httpBackend.expectGET('/api/events').respond objects
      $httpBackend.expectGET('/api/others').respond others
      events = Event.list()
      Other = Collection('others')
      other_objects = Other.list()
      $rootScope.$apply()
      $httpBackend.flush()
      expect(events).toEqualData objects
      expect(other_objects).toEqualData others

      #Ensure there is no further request
      Event.list()
      Other.list()
      $rootScope.$apply()

      #Load more objects for events
      $httpBackend.expectGET('/api/events?last=22').respond objects_more
      Event.more()
      $rootScope.$apply()
      $httpBackend.flush()
      expect(events).toEqualData objects.concat objects_more
      #Rfresh the list of others
      $httpBackend.expectGET('/api/others?first=21').respond others_new
      Other.refresh()
      $rootScope.$apply()
      $httpBackend.flush()
      expect(other_objects).toEqualData others_new.concat others


    it 'should be able to create a item before load', ->
      newData = title:"new item", avenue: "here"
      newId = id:100
      $httpBackend.expectPOST('/api/events').respond (method, url, data, headers)->
        [201, JSON.stringify(_.extend(JSON.parse(data), newId)), ""]

      #Create a new instance then save
      newItem = Event.create(newData)
      newItem.$save().then(success,fail).finally(always)
      expect(newItem.$resolved).toBeFalsy()

      $rootScope.$apply()
      $httpBackend.flush()
      expect(newItem.$resolved).toBeTruthy()
      expect(success.calls.length).toEqual(1)
      expect(newItem).toEqualData(_.extend(newData, newId))

    it "should be able to post/get/delete a sub url", ->

      #Post to a sub URI
      ret = null
      newId = id:100
      postData = body: "comment body"
      Event.postSub(21, 'comments', postData).then((data)-> ret = data)
      $httpBackend.expectPOST('/api/events/21/comments').respond (method, url, data, headers)->
        [201, JSON.stringify(_.extend(JSON.parse(data), newId)), ""]
      $rootScope.$apply()
      $httpBackend.flush()
      expect(ret).toEqualData(_.extend(postData, newId))

      #Delete to a sub URI
      ret = null
      Event.deleteSub(21, 'attandees').then((data)-> ret = data)
      # Bug: connot return a array
      $httpBackend.expectDELETE('/api/events/21/attandees').respond [{"id": 5, "name": "\u65e0\u950b5", "profile_image_url": "http://q.qlogo.cn/qqapp/100497365/ECD7A71A23A5207BE978F715FB7A3D1A/40", "url": "", "origin": "q"}]
      $rootScope.$apply()
      $httpBackend.flush()
      expect(ret.status).toEqual(0)

      #Query a subset
      sublist = Event.listSub(21, 'comments')
      sublist.$promise.then(success,fail).finally(always)
      expect(sublist.$resolved).toBeFalsy()
      comments = [{id:1, body:"c1"},{id:2, body:"c2"}]
      $httpBackend.expectGET('/api/events/21/comments').respond comments
      $rootScope.$apply()
      $httpBackend.flush()
      expect(sublist).toEqualData(comments)
      expect(sublist.$resolved).toBeTruthy()

      #Delete an item in subset
      Event.deleteSubItem(21, 'comments', 1).then((data)-> ret = data)
      $httpBackend.expectDELETE('/api/events/21/comments/1').respond status: 1
      $rootScope.$apply()
      $httpBackend.flush()
      expect(ret.status).toEqual(1)










