
angular.module('app.photo', [])
  .directive('sliderBox', ()->
    (scope, element, attr, ctrl) ->
      slider = new ionic.views.Slider
        el: element[0]

      element.ready ->
        slider.load()
  )
  .controller( 'PhotoDetailCtrl', ($scope)->

  )