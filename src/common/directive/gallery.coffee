

angular.module( 'Gallery', [])
  .directive('galleryCarousel', ()->
    link: (scope, el, attr)->
      gallery = null
      scope.$watch attr.links, (links)->

        if links and links.length
          gallery = blueimp.Gallery links,
            container: el[0]
            carousel: true

      scope.$watch attr.moreLinks, (links)->
        if gallery and links
          gallery.add links
  )
  .directive('galleryLinks', ()->
    (scope, el, attr)->

      el[0].onclick = (event)->
        event = event || window.event
        target = event.target || event.srcElement
        link = if target.src then target.parentNode else target
        options = index: link, event: event
        links = this.getElementsByTagName('a')
        blueimp.Gallery(links, options)

  )
  .directive('galleryFull', ()->
    (scope, el, attr)->
  )
