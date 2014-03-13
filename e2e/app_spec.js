
describe('homepage', function() {
	var ptor;
	beforeEach(function() {
	  browser.get('http://127.0.0.1:8080/m/bin/index.html');
	  ptor = protractor.getInstance();
	});

  it('should have 10 elements', function() {
    // test goes here
	var elems = element.all(by.repeater('e in objects'));
	expect(elems.count()).toBe(10);
  });
  
  it('includes a user gravatar per-element', function() {
    var elems = element.all(by.repeater('e in objects'));
    elems.first().then(function(elm) {
	    elm.findElement(by.tagName('img')).then(function(img) {
	        img.getAttribute('src').then(function(src) {
	          expect(src).toMatch(/u\/album/);
	        });
	    });
    });
  });
  
  it('should navigate to the /edit page when clicking add', function() {
    element(by.css('.bar button')).click();
    expect(ptor.getCurrentUrl()).toMatch(/\/edit/);
  });
  
  //element(by.input('repo.name')).sendKeys('angular/angular.js\n');
  //expect(ptor.isElementPresent(by.id('repoform'))).toBe(false);
  
});