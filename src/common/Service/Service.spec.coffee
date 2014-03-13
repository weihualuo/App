
describe 'Service', ->
  $timeout = null
  Service = null

  beforeEach module 'Service'
#  beforeEach ->  jasmine.Clock.useMock()
  beforeEach inject (_Service_, _$timeout_) ->
    $timeout = _$timeout_
    Service = _Service_

  describe 'noRepeat', ->

    it 'should be true at first', inject ()->
      expect(Service.noRepeat('first',2000)).toBeTruthy()

    it 'should be false before timeout', inject ()->
      expect(Service.noRepeat('first')).toBeTruthy()
      expect(Service.noRepeat('first')).toBeFalsy()
      expect(Service.noRepeat('first', 1000)).toBeFalsy()
      $timeout.flush()
  #    jasmine.Clock.tick(3000)
      expect(Service.noRepeat('first', 3000)).toBeTruthy()
      expect(Service.noRepeat('first', 3000)).toBeFalsy()
      $timeout.flush()
      expect(Service.noRepeat('first', 3000)).toBeTruthy()

    it 'should work for multiple objecs', inject ()->
      expect(Service.noRepeat('first')).toBeTruthy()
      expect(Service.noRepeat('first')).toBeFalsy()
      expect(Service.noRepeat('second')).toBeTruthy()
      expect(Service.noRepeat('second')).toBeFalsy()
      $timeout.flush()
      expect(Service.noRepeat('first')).toBeTruthy()
      expect(Service.noRepeat('second')).toBeTruthy()

  describe 'fileReader', ->
    success = jasmine.createSpy 'success'
    fail = jasmine.createSpy 'fail'
    always = jasmine.createSpy 'always'

    it 'should return a promise', ->
      file = new Blob()
      promise = Service.readFile(file)
      promise.then(success,fail).finally(always)




