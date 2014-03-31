
angular.module( 'ui.popup', [])

  .factory('Popup', ($rootScope, $location, $compile, $animate, $timeout, $q, $document, MESSAGE)->

    alert : (message)->
      template =
                 '<div class="popup-backdrop box-center" ng-click="onClose()">' +
                    '<div class="popup-win-msg box-center">'+message+'</div>'+
                 '</div>'

      scope = $rootScope.$new(true)
      angularDomEl = angular.element(template)
      element = $compile(angularDomEl)(scope)

      hidePopup = ->
        $animate.leave(element)
        scope.$destroy()

      parent = angular.element($document[0].body)
      $animate.enter element, parent
      scope.onClose = -> hidePopup()

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

    loading : (promise, silent)->

      template = """
                 <div class="popup-backdrop box-center">
                  <div><i class="icon icon-large ion-loading-d"></i></div>
                 </div>
                 """
      element = angular.element(template)
      hidePopup = ->
        $animate.leave(element)
      parent = angular.element($document[0].body)
      $animate.enter element, parent

      if promise
        if !silent
          promise.catch => @alert MESSAGE.LOAD_FAILED
        promise.finally hidePopup

      #return a end function to manully hide the view
      end: hidePopup
  )
  .factory('Modal', ($rootScope, $compile, $animate, $timeout, $location, $q, $http, $templateCache, $document, $window, PrefixedEvent)->
    (locals, template, hash, url, backdrop)->

      backdrop ?= """
                  <div class="popup-backdrop enabled" ng-click="onClose($event)"></div>
                  """
      hash ?= 'modal'
      deferred = $q.defer()
      scope = $rootScope.$new(true)
      angular.extend scope, locals
      param = undefined
      ready = false
      savedState = null
      element = null
      onPopup = ->
        # Re-push if entering or removing
        if !ready
          $timeout (->$location.hash(hash))
          return
        ready = false
        $window.onpopstate = savedState
        $timeout removeModal

      scope.$close = (ret)->
        #popup hash history
        if ready and $window.onpopstate is onPopup
          param = ret
          history.back()

      scope.$on 'destroyed', (e, transiting)->
        if transiting
          ready = false
          PrefixedEvent element, "TransitionEnd", ->
            ready = true
            history.back() if $window.onpopstate is onPopup
        else
          scope.$close()

      body = $document[0].body
      if !backdrop
        parent = angular.element(body)
      else
        parent = $compile(backdrop)(scope)
        body.appendChild(parent[0])
        scope.onClose = (e)->
          target = e.target || e.srcElement
          if target is parent[0]
            scope.$close()

      removeModal = ->
        if param?
          deferred.resolve(param)
        else
          deferred.reject()
        scope.$destroy()
        $animate.leave element, ->
          parent.remove() if backdrop

      angularDomEl = angular.element(template)

      enterModal = ->
        element = $compile(angularDomEl)(scope)
        $animate.enter element, parent, null, ->
          ready = true
          #To be compatible with browser and android back button
        $location.hash(hash)
        savedState = $window.onpopstate
        $window.onpopstate = onPopup

      if url
        $http.get(url, cache: $templateCache).then(
          (result)->
            angularDomEl.html(result.data)
            enterModal()
          ()->
            deferred.reject()
            parent.remove() if backdrop
            console.log "Failed to load", url
          )
      else
        enterModal()

      #Return
      ret =
        promise: deferred.promise
        end: scope.$close

  )
  .factory('TogglePane', (Modal)->
    panes = {}
    (param)->
      {id, locals, template, url, hash, backdrop, success, fail, always} = param
      if panes[id]
        panes[id].end()
        panes[id] = null
      else if id
        panes[id] = Modal locals, template, hash, url, backdrop
        panes[id].promise.then(success, fail).finally ->
          panes[id] = null
          if always then always()
  )


