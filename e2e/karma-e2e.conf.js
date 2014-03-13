
module.exports = function(config) {
  config.set({
    basePath: '../',
	frameworks : ["ng-scenario"],
	files : [
	  'e2e/scenarios.coffee'
	],
	
    preprocessors: {
      'e2e/scenarios.coffee': 'coffee',
    },
		  
	autoWatch : false,

	browsers : ['Firefox'],
	singleRun : true,
	proxies : {
	  '/m/': 'http://localhost:8080/m/',
	  '/u/': 'http://localhost:8080/u/',
	  '/api/': 'http://localhost:8080/api/',
	},

	junitReporter : {
	  outputFile: 'e2e/e2e.xml',
	  suite: 'e2e'
	}

  });
};