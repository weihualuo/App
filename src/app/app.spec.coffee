

xdescribe 'app', ->
  $rootScope = null
  $httpBackend = null
  Many = null
  Single = null
  $q = null

  beforeEach module 'app'

  beforeEach inject (_$httpBackend_, _Many_, _Single_,_$rootScope_, _$q_)->
    Many = _Many_
    Single = _Single_
    $httpBackend = _$httpBackend_
    $rootScope = _$rootScope_
    $q = _$q_

  describe 'promise test', ->
    success = null
    fail = null
    always = null
    beforeEach ->
      success = jasmine.createSpy 'success'
      fail = jasmine.createSpy 'fail'
      always = jasmine.createSpy 'always'
    it 'should call success after resolved', ->
      deferred = $q.defer()
      promise = deferred.promise
      promise.then(success,fail).finally(always)
      deferred.resolve()
      $rootScope.$apply()
      expect(success.calls.length).toEqual(1)
      promise.then(success,fail).finally(always)
      $rootScope.$apply()
      expect(success.calls.length).toEqual(2)
      expect(always.calls.length).toEqual(2)

    it 'should call failed after rejected', ->
      deferred = $q.defer()
      promise = deferred.promise
      promise.then(success,fail).finally(always)
      deferred.reject()
      $rootScope.$apply()
      expect(fail.calls.length).toEqual(1)
      promise.then(success,fail).finally(always)
      $rootScope.$apply()
      expect(fail.calls.length).toEqual(2)
      expect(always.calls.length).toEqual(2)

  xdescribe 'Scope test', ->

    it "should watch", ->
      obj = a:"aa", b:[1,2,3], c:{c1:1}
      scope = $rootScope.$new()
      scope.obj = obj

      deepChange = jasmine.createSpy 'deepChange'
      change = jasmine.createSpy 'change'
      collectChange = jasmine.createSpy 'collectChange'

      scope.$watch 'obj', ((n, o)-> change())
      scope.$watch 'obj', ((n, o)-> deepChange()), true
      scope.$watchCollection 'obj', ((n, o)-> collectChange())

      scope.$digest()
      expect(change).toHaveBeenCalled()
      expect(deepChange).toHaveBeenCalled()
      expect(collectChange).toHaveBeenCalled()

      objcopy = angular.copy scope.obj
      scope.obj = objcopy
      scope.$digest()
      expect(change.calls.length).toEqual(2)         #changed
      expect(collectChange.calls.length).toEqual(2)  #changed
      expect(deepChange.calls.length).toEqual(1)     #unchanged


      scope.obj.b.push 4
      scope.$digest()
      expect(change.calls.length).toEqual(2)          #unchanged
      expect(collectChange.calls.length).toEqual(2)   #unchanged
      expect(deepChange.calls.length).toEqual(2)      #changed

      scope.obj.d = "new"
      scope.$digest()
      expect(change.calls.length).toEqual(2)          #unchanged
      expect(collectChange.calls.length).toEqual(3)   #changed
      expect(deepChange.calls.length).toEqual(3)      #changed

      scope.obj.a = "value changed"
      scope.$digest()
      expect(change.calls.length).toEqual(2)          #unchanged
      expect(collectChange.calls.length).toEqual(4)   #changed
      expect(deepChange.calls.length).toEqual(4)      #changed

