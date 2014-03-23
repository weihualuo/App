
angular.module( 'ui.popup', [])

  .factory('Popup', ($rootScope, $location, $compile, $animate, $timeout, $q, $http, $templateCache)->

    alert : (message)->

      template = '<div class="popup-backdrop"><div class="popup-win">' +
                    message +
                  '</div></div>'
      element = angular.element(template)
      popWin = element[0].firstChild

      hidePopup = ->
        #$animate.leave(element)
        element.remove()


      parent = angular.element(document.body)
      document.body.appendChild(element[0])
      #TODO can not bind on click ?
      #$animate.enter(element, parent)
      element.on('click', hidePopup)

      popWin.style.marginLeft = (-popWin.offsetWidth) / 2 + 'px'
      popWin.style.marginTop = (-popWin.offsetHeight) / 2 + 'px'

      #Hide the popup after 2second
      $timeout (->hidePopup()), 2000

    confirm : (message)->

      deferred = $q.defer()

      template = '<div class="popup-backdrop"><div class="popup-win">' +
                   message +
                 '<br><br>
                  <a class="btn btn-primary" style="margin: 0 10px">确定</a>
                  <a class="btn" style="margin: 0 10px">取消</a>
                  </div></div>'
      element = angular.element(template)
      popWin = element[0].firstChild
      hidePopup = -> element.remove()
      onOK = ->
        hidePopup()
        deferred.resolve()
      onCancel = ->
        hidePopup()
        deferred.reject()
      btns = popWin.querySelectorAll('a')
      btns[0].addEventListener('click', onOK)
      btns[1].addEventListener('click', onCancel)
      element.bind('click', onCancel)

      document.body.appendChild(element[0])
      popWin.style.marginLeft = (-popWin.offsetWidth) / 2 + 'px'
      popWin.style.marginTop = (-popWin.offsetHeight) / 2 + 'px'

      #Return a promise
      deferred.promise

    options : (items)->

      deferred = $q.defer()
      scope = $rootScope.$new(true)
      scope.items = items
      scope.onSelect = (index)->
        hidePopup()
        deferred.resolve(index)
      scope.onCancel = ->
        hidePopup()
        deferred.reject()

      template = '<div class="options-backdrop" ng-click="onCancel()">
                    <ul class="list options-content">
                      <li class="item item-divider" ng-repeat="item in items" ng-click="onSelect($index)">{{item}}</li>
                    </div>
                  </ul>'
      element = $compile(template)(scope)
      popWin = element.children()[0]
      #SCOPE must be destroyed
      hidePopup = ->
        element.remove()
        scope.$destroy()

      document.body.appendChild(element[0])
      element.ready ->
        popWin.style.marginTop = (-popWin.offsetHeight) / 2 + 'px'

      #Return a promise
      deferred.promise

    loading : (promise, title, failedMsg)->
      title ?= ''
      template = '<div class="popup-backdrop"><div class="popup-win"><h5>' +
                    title +
                 '</h5><i class="icon icon-large ion-load-c loading-rotate"></i></div></div>'

      element = angular.element(template)
      popWin = element[0].firstChild

      hidePopup = -> element.remove()

      document.body.appendChild(element[0])
      popWin.style.marginLeft = (-popWin.offsetWidth) / 2 + 'px'
      popWin.style.marginTop = (-popWin.offsetHeight) / 2 + 'px'

      if promise
        if failedMsg
          promise.catch => @alert failedMsg
        promise.finally hidePopup

      #return a end function to manully hide the view
      end: hidePopup
  )
  .factory('Modal', ($rootScope, $compile, $animate, $timeout, $location, $q, $http, $templateCache, $document, $window)->
    (templateUrl, locals, template, hash, full)->

      parentTpl = """
                  <div class="popup-backdrop"></div>
                 """
      deferred = $q.defer()
      scope = $rootScope.$new(true)
      angular.extend scope, locals
      param = undefined
      scope.$close = (ret)->
        #popup hash history
        param = ret
        history.back()

      body = $document[0].body
      if full
        parent = angular.element(body)
      else
        parent = $compile(parentTpl)(scope)
        body.appendChild(parent[0])
        parent.on 'click', (e)->
          if e.target == parent[0]
            scope.$close()

      element = null

      hidePopup = ()->

        $animate.leave element, ->
          body.removeChild(parent[0]) if !full
          scope.$destroy()
          if param?
            deferred.resolve(param)
          else
            deferred.reject()


      template ?= '<div class="popup-modal popup-in-up"></div>'
      angularDomEl = angular.element(template)

      $http.get(templateUrl, cache: $templateCache)
        .then(
          (result)->
            angularDomEl.html(result.data)
            element = $compile(angularDomEl)(scope)
            $animate.enter element, parent, null, ->
              console.log "element ready"

            #To be compatible with browser and android back button
            $location.hash(hash or 'modal')
            savedState = $window.onpopstate
            $window.onpopstate = ->
              $timeout hidePopup
              $window.onpopstate = savedState

          ()->
            deferred.reject()
            console.log "Failed to load", templateUrl
        )

      #Return
      ret =
        promise: deferred.promise
        end: scope.$close

  )
  .factory('TogglePane', (Modal)->
    panes = {}
    (param)->
      {id, locals, template, url, hash, full, success, fail, always} = param
      if panes[id]
        panes[id].end()
        panes[id] = null
      else if id
        panes[id] = Modal url, locals, template, hash, full
        panes[id].promise.then(success, fail).finally ->
          panes[id] = null
          if always then always()
  )


