
describe 'Model factory', ->

  events = [ {"id": 21,"title": "title21"} , {"id": 22,"title": "title22"}]
  events_new = [ {"id": 11,"title": "title11"} , {"id": 12,"title": "title12"}]
  events_more = [ {"id": 31,"title": "title31"} , {"id": 32,"title": "title32"}]
  item = id:21, title: "title21", desc: "this is detail information"
  item2 = id:22, title: "title22", desc: "this is detail information 2"

  others = [ {"id": 21,"other": "other21"} , {"id": 22,"other": "other22"}]
  others_new = [ {"id": 11,"other": "other11"} , {"id": 12,"other": "other12"}]
  others_more = [ {"id": 31,"other": "other31"} , {"id": 32,"other": "other32"}]

  meta = key: 'value', user: {id:1, name: "my name"}
  meta2 = key2: 'value2', user2: {id:2, name2: "my name2"}

  collection =
    meta: more:15
    results: events


#  // Utils
#  // Apply "sanitizeRestangularOne" function to an array of items
  sanitizeRestangularAll = (items) ->
    all = _.map items, (item)->
      sanitizeRestangularOne(item)
    sanitizeRestangularOne(all)

#  // Remove all Restangular/AngularJS added methods in order to use Jasmine toEqual between the retrieve resource and the model
  sanitizeRestangularOne = (item)->
    _.omit(item, "route", "parentResource", "getList", "get", "post", "put", "remove", "head", "trace", "options", "patch",
      "$then", "$resolved", "restangularCollection", "customOperation", "customGET", "customPOST",
      "customPUT", "customDELETE", "customGETLIST", "$getList", "$resolved", "restangularCollection", "one", "all","doGET", "doPOST",
      "doPUT", "doDELETE", "doGETLIST", "addRestangularMethod", "getRestangularUrl", "several", "getRequestedUrl", "clone",
      "reqParams", "withHttpConfig", "oneUrl", "allUrl", "getParentList")

  beforeEach module 'Model'

  beforeEach ->
    this.addMatchers
      toEqualData: (expected)->
        angular.equals(this.actual, expected)

  $rootScope = null
  $httpBackend = null
  $timeout = null
  Many = null
  Single = null
  success = null
  fail = null
  always = null


  beforeEach inject (_$httpBackend_, _Many_, _Single_,_$rootScope_,_$timeout_)->
    Many = _Many_
    Single = _Single_
    $httpBackend = _$httpBackend_
    $rootScope = _$rootScope_
    $timeout = _$timeout_
    success = jasmine.createSpy 'success'
    fail = jasmine.createSpy 'fail'
    always = jasmine.createSpy 'always'


  describe 'Single factory', ->

    it 'should load only once on first visit', ->
      $httpBackend.expectGET('/api/meta').respond meta
      single = Single('meta')
      object = single.get()
      expect(object.$resolved).toBeFalsy()
      object.$promise.then(success,fail).finally(always)
      $rootScope.$apply()
      expect(sanitizeRestangularOne object).toEqualData({})
      $httpBackend.flush()
      expect(object.$resolved).toBeTruthy()
      expect(object).toEqualData(meta)

      single.get()
      expect(object.$resolved).toBeTruthy()
      object.$promise.then(success,fail).finally(always)
      #apply should be used to verify there is no Unexpected request
      $rootScope.$apply()
      expect(success.calls.length).toEqual(2)

    it 'should alwayse refresh by force parameter', ->
      $httpBackend.expectGET('/api/meta').respond meta
      single = Single('meta')
      object = single.get()
      $rootScope.$apply()
      $httpBackend.flush()
      expect(object).toEqualData(meta)

      newItem = newkey: "new value"
      $httpBackend.expectGET('/api/meta').respond newItem
      single.get(true)
      #What resolved should be?
      expect(object.$resolved).toBeTruthy()
      $rootScope.$apply()
      $httpBackend.flush()
      expect(object).toEqualData(newItem)


    it 'should be able to serve for multiple models', ->
      $httpBackend.expectGET('/api/meta').respond meta
      $httpBackend.expectGET('/api/meta2').respond meta2

      single1 = Single 'meta'
      single2 = Single 'meta2'
      obj1 = single1.get()
      obj2 = single2.get()
      $rootScope.$apply()
      $httpBackend.flush()
      expect(obj1).toEqualData(meta)
      expect(obj2).toEqualData(meta2)

    it "Should call the failed function if respond a error", ->
      #Response with 404
      $httpBackend.expectGET('/api/meta').respond 404
      single = Single('meta')
      object = single.get()
      expect(object.$resolved).toBeFalsy()
      object.$promise.then(success,fail).finally(always)
      $rootScope.$apply()
      $httpBackend.flush()
      expect(object.$resolved).toBeTruthy()
      expect(fail.calls.length).toEqual(1)
      expect(always.calls.length).toEqual(1)
      expect(success.calls.length).toEqual(0)
      object.$promise.then(success,fail).finally(always)
      $rootScope.$apply()
      expect(fail.calls.length).toEqual(2)

  describe 'Many factory', ->

    Event = null
    beforeEach ->
      Event = Many('events')


    it "Should return the list with promise on query, only for the first time", ->
      $httpBackend.expectGET('/api/events').respond collection
      #Reqeust the list should return a empty array with $promise
      objects = Event.list()
      objects.$promise.then(success,fail).finally(always)
      expect(objects).toEqualData([])
      expect(objects.$resolved).toBeFalsy()

      #Reponse with objects successful
      $rootScope.$apply()
      $httpBackend.flush()
      expect(objects).toEqualData(events)
      expect(objects.$resolved).toBeTruthy()
      expect(objects.route).toEqual('events')
      expect(success).toHaveBeenCalled()
      expect(always).toHaveBeenCalled()
      expect(fail.calls.length).toEqual(0)

      #Should return the same list
      list = Event.list()
      list.$promise.then(success,fail).finally(always)
      $rootScope.$apply()
      expect(list.$resolved).toBeTruthy()
      expect(list).toEqual(objects)
      expect(success.calls.length).toEqual(2)

    it "Should get meta information", ->
      $httpBackend.expectGET('/api/events').respond collection
      objects = Event.list()
      $rootScope.$apply()
      $httpBackend.flush()
      expect(objects).toEqualData(events)
      expect(objects.meta).toEqual(collection.meta)


    it "Should update list if param changed", ->
      $httpBackend.expectGET('/api/events').respond events
      objects = Event.list()
      $rootScope.$apply()
      $httpBackend.flush()

      $httpBackend.expectGET('/api/events?ca=2&ro=1').respond events_new
      param = {ro:1, ca:2}
      list = Event.list(param)
      expect(list.$resolved).toBeFalsy()
      $rootScope.$apply()
      $httpBackend.flush()
      expect(list.$resolved).toBeTruthy()
      expect(sanitizeRestangularAll list).toEqualData sanitizeRestangularAll events_new


    it 'should refresh with param and insert objects before the first', ->
      $httpBackend.expectGET('/api/events?ca=2&ro=1').respond events
      expect(Event.refresh()).toBeUndefined()
      param = {ro:1, ca:2}
      objects = Event.list(param)
      $rootScope.$apply()
      $httpBackend.flush()
      expect(sanitizeRestangularAll objects).toEqualData sanitizeRestangularAll events

      $httpBackend.expectGET('/api/events?ca=2&first=21&ro=1').respond events_new
      Event.refresh().then(success,fail).finally(always)
      $rootScope.$apply()
      $httpBackend.flush()
      expect(sanitizeRestangularAll objects).toEqualData sanitizeRestangularAll events_new.concat events

    it 'should refresh items if initial objects is empty', ->
      $httpBackend.expectGET('/api/events').respond []
      objects = Event.list()
      expect(objects).toEqualData([])
      expect(objects.$resolved).toBeFalsy()
      $rootScope.$apply()
      $httpBackend.flush()
      expect(objects).toEqualData([])

      $httpBackend.expectGET('/api/events').respond events_new
      Event.refresh().then(success,fail).finally(always)
      $rootScope.$apply()
      $httpBackend.flush()
      expect(sanitizeRestangularAll objects).toEqualData sanitizeRestangularAll events_new



    it 'should load more item with param insert objects after the last', ->
      $httpBackend.expectGET('/api/events?st=1').respond events
      expect(Event.more()).toBeUndefined()
      model = Many('events')
      param = {st:1}
      objects = Event.list(param)
      $rootScope.$apply()
      $httpBackend.flush()
      expect(sanitizeRestangularAll objects).toEqualData sanitizeRestangularAll events

      $httpBackend.expectGET('/api/events?last=22&st=1').respond events_more
      model.more().then(success,fail).finally(always)
      $rootScope.$apply()
      $httpBackend.flush()
      expect(sanitizeRestangularAll objects).toEqualData sanitizeRestangularAll events.concat events_more

    it 'should fetch item details only on the first visit', ->
      $httpBackend.expectGET('/api/events').respond events
      objects = Event.list()
      $rootScope.$apply()
      $httpBackend.flush()

      $httpBackend.expectGET('/api/events/21').respond item
      cur = Event.get 21
      expect(cur.$resolved).toBeFalsy()
      expect(cur).toEqual(objects[0])
      cur.$promise.then(success,fail).finally(always)
      $rootScope.$apply()
      $httpBackend.flush()

      expect(cur.$resolved).toBeTruthy()
      expect(cur).toEqual(objects[0])
      expect(cur).toEqualData(item)

      $httpBackend.expectGET('/api/events/22').respond item2
      cur = Event.get 22
      expect(cur).toEqual(objects[1])
      $rootScope.$apply()
      $httpBackend.flush()
      expect(cur).toEqual(objects[1])
      expect(cur).toEqualData(item2)

      # should get the same object on the later request
      cur1 = Event.get 21
      $rootScope.$apply()
      expect(cur1.$resolved).toBeTruthy()
      expect(cur1).toEqual(objects[0])
      cur1.$promise.then(success,fail).finally(always)
      cur2 = Event.get 22
      $rootScope.$apply()
      expect(success.calls.length).toEqual(2)
      expect(cur2).toEqual(objects[1])

    it "should be able fetch item details which not in list", inject (Restangular)->
      $httpBackend.expectGET('/api/events/21').respond item
      model = Event
      cur = model.get 21
      expect(cur).toEqualData(Restangular.one 'events', 21)
      $rootScope.$apply()
      $httpBackend.flush()
      expect(cur).toEqualData(item)

      # should get the same object on the later request
      cur2 = model.get 21
      $rootScope.$apply()
      expect(cur2).toEqual(cur)


    it "should always fetch item details by force", inject ()->
      $httpBackend.expectGET('/api/events/21').respond item
      model = Event
      cur = model.get 21
      $rootScope.$apply()
      $httpBackend.flush()
      expect(cur).toEqualData(item)

      extra = extra:"extra value", title: "title new"
      $httpBackend.expectGET('/api/events/21').respond extra
      model.get 21, true
      #What resolved should be?
      expect(cur.$resolved).toBeTruthy()
      $rootScope.$apply()
      $httpBackend.flush()
      expect(cur).toEqualData(extra)


    it 'should be able to serve for multiple models at the same time ', ->
      $httpBackend.expectGET('/api/events').respond events
      $httpBackend.expectGET('/api/others').respond others
      model = Many('events')
      other = Many('others')
      objects = model.list()
      other_objects = other.list()
      $rootScope.$apply()
      $httpBackend.flush()

      expect(sanitizeRestangularAll objects).toEqualData sanitizeRestangularAll events
      expect(sanitizeRestangularAll other_objects).toEqualData sanitizeRestangularAll others
      #no further request
      model.list()
      other.list()
      $rootScope.$apply()

      $httpBackend.expectGET('/api/events?last=22').respond events_more
      model.more()
      $rootScope.$apply()
      $httpBackend.flush()
      expect(sanitizeRestangularAll objects).toEqualData sanitizeRestangularAll events.concat events_more

      $httpBackend.expectGET('/api/others?first=21').respond others_new
      other.refresh()
      $rootScope.$apply()
      $httpBackend.flush()
      expect(sanitizeRestangularAll other_objects).toEqualData sanitizeRestangularAll others_new.concat others


    it 'should be able to create a item before load', ->
      p = title:"new item", avenue: "here"
      newId = id:100
      $httpBackend.expectPOST('/api/events').respond (method, url, data, headers)->
        [201, JSON.stringify(_.extend(JSON.parse(data), newId)), ""]

      model = Event
      newItem = null
      model.new(p).then(
        (d)-> newItem = d
      )
      $rootScope.$apply()
      $httpBackend.flush()
      expect(sanitizeRestangularOne newItem).toEqualData(_.extend(p, newId))

    it 'should be able to create a item after load', ->
      $httpBackend.expectGET('/api/events?ro=1').respond events
      model = Many('events')
      objects = model.list(ro:1)
      $rootScope.$apply()
      $httpBackend.flush()

      p = title:"new item", avenue: "here"
      newId = id:100
      $httpBackend.expectPOST('/api/events').respond (method, url, data, headers)->
        [201, JSON.stringify(_.extend(JSON.parse(data), newId)), ""]

      newItem = null
      model.new(p).then(
        (d)-> newItem = d
      )
      $rootScope.$apply()
      $httpBackend.flush()

      expect(sanitizeRestangularOne newItem).toEqualData(_.extend(p, newId))

    it "Should call the failed function if respond a error", ->
      #Response with 404
      $httpBackend.expectGET('/api/events').respond 404
      list = Event.list()
      list.$promise.then(success,fail).finally(always)
      $rootScope.$apply()
      $httpBackend.flush()
      expect(list.$resolved).toBeTruthy()
      expect(fail.calls.length).toEqual(1)

      $httpBackend.expectGET('/api/events/21').respond 404
      cur = Event.get 21
      cur.$promise.then(success,fail).finally(always)
      $rootScope.$apply()
      $httpBackend.flush()
      expect(cur.$resolved).toBeTruthy()
      expect(fail.calls.length).toEqual(2)






