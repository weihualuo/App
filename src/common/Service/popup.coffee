
angular.module( 'Popup', [])

  .factory('Popup', ($rootScope, $location, $compile, $animate, $timeout, $q, $document)->

    alert : (message)->
      template =
                 '<div class="popup-backdrop box-center">' +
                    '<div class="popup-msg box-center">'+message+'</div>'+
                 '</div>'

      element = angular.element(template)
      ready = no
      $timeout (->ready = yes), 1000
      hidePopup = ->
        ready = no
        $animate.leave(element)
      parent = angular.element($document[0].body)
      $animate.enter element, parent
      #enable event after 1second
      element.on 'touchend mouseup', ->
        if ready
          ready = no
          $timeout hidePopup
      #Hide the popup after 2second
      $timeout hidePopup, 2000

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

    loading : (promise, options={})->

      element = angular.element('<div class="popup-backdrop box-center"></div>')
      win = angular.element('<div class="loading-win box-center"><i class="icon icon-large ion-loading-d"></i></div>')
      element.append(win)

      if options.showWin
        win.addClass('enabled')
      hidePopup = ->
        $animate.leave(element)
      parent = angular.element($document[0].body)
      $animate.enter element, parent

      if promise
        if options.failMsg
          promise.catch => @alert options.failMsg
        promise.finally hidePopup

      #return a end function to manully hide the view
      end: hidePopup
  )
  .factory('Modal', ($rootScope, $compile, $animate, $timeout, $location, $q, $http, $templateCache, $controller, $document, $window)->
    (options)->

      {locals, scope, template, controller, url, hash, backdrop, parent} = options
      backdrop ?= angular.element '<div class="popup-backdrop box-center enabled"></div>'
      parent ?= angular.element($document[0].body)
      hash ?= options.id
      scope ?= $rootScope
      scope = scope.$new()
      angular.extend scope, locals
      if controller
        scope.$controller = $controller(controller, $scope:scope)

      param = undefined
      ready = false
      savedState = null
      element = null
      deferred = $q.defer()
      onPopup = ->
        # Re-push if entering or removing
        if !ready
          $timeout (->$location.hash(hash))
          return
        ready = false
        $window.onpopstate = savedState
        $timeout removeModal

      closeModal = (ret)->
        #popup hash history
        if ready and $window.onpopstate is onPopup
          param = ret
          history.back()

      #emit by sidepane or something
      scope.$on 'content.closed', -> closeModal()


      if backdrop
        parent.append(backdrop)
        parent = backdrop
        #ng click not work with child form element
        if options.closeOnBackdrop
          backdrop.on 'touchend mouseup', (e)->
            target = e.target || e.srcElement
            if target is backdrop[0] then closeModal()

      removeModal = ->
        if param?
          deferred.resolve(param)
        else
          deferred.reject()
        scope.$destroy()
        #console.log 'leaving'
        $animate.leave element, ->
          #console.log 'leaved'
          backdrop.remove() if backdrop

      angularDomEl = angular.element(template)

      enterModal = ->
        element = $compile(angularDomEl)(scope)
        $animate.enter element, parent, null, ->
          scope.$broadcast 'modal.ready'
          ready = true
          #To be compatible with browser and android back button
        $location.hash(hash)
        savedState = $window.onpopstate
        $window.onpopstate = onPopup
        scope.$broadcast 'modal.enter'

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
      scope.modal =
        close: closeModal
        promise: deferred.promise
  )
  .factory('ToggleModal', (Modal)->
    panes = {}
    (param)->
      id = param.id
      if panes[id]
        panes[id].close()
        panes[id] = null
      else if id
        panes[id] = modal = Modal param
        modal.promise.then(param.success, param.fail).finally ->
          panes[id] = null
          param.always?()
        modal
  )



