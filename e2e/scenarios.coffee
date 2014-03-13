
describe 'my app', ->

  describe 'home list view', ->
    beforeEach ->
      browser().navigateTo('/m/build/index.html')

    it 'should automatically redirect to / by default', ->
      expect(browser().location().url()).toBe("/")
      expect(binding('title')).toBe('集结号')

    it 'should load 10 items at firest', ->
      expect(repeater('ul li').count()).toBe(10);

    it 'should load 10 more items after click more', ->
      element('#pullUp').click()
      expect(repeater('ul li').count()).toBe(20);
