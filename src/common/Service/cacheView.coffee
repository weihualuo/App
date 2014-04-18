

angular.module( 'CacheView', [])
  .value('viewStack',
    []
  )
  .factory('ViewFactory', ()->
    class View
      constructor: (@element, @name, @scope, @params) ->
        @ctrl = @scope.$controller
    View
  )
  .factory('Nav', ($route, $location, viewStack)->

    push = inherit = false
    data = null

    api =

      reset: ->
        push = inherit = false
        data = null

      inherit: (value)->
        inherit = value if value?
        inherit
      push: (value)->
        push = value if value?
        push

      data: -> data

      back: (option)->
        if viewStack.length
          #console.log "just history.back"
          history.back()
        else if option
          #console.log "no stack, go", option.name
          @go option

      go: (option)->
        {name, data, param, search, hash, push, inherit} = option

        route = _.find $route.routes, name:name
        return no if not route

        replace = not push

        #View is not in stack
        path = route.originalPath
        _.each param, (value, key)->
          re = new RegExp(':'+key)
          path = path.replace(re, value)

        $location.replace() if replace
        $location.path path
        $location.search search or {}
        $location.hash hash or null

        #console.log "set url", $location.url(), replace


  )
  .factory('ViewManager', (Nav, $animate, Service, viewStack, Tansformer)->
    current = null
    $element = null
    stack = viewStack

    removeView = (view)->
      #in case of cached view, scope will be reused
      #i case of non-cached view, scope will be detroyed on remove
      #console.log "removing", view.name, view.scope
      if view.cached
        Service.disconnectScope(view.scope)
      else
        view.scope.$destroy()

      view.ctrl.leave ->
        Tansformer.leave(view.element, view.ctrl.transitOut)

    enterView = (view, cached)->
      #console.log "enter #{view.name} with cache=#{cached}"
      if cached
        Service.reconnectScope(view.scope)
        view.element.removeClass('replaced')

      view.ctrl.enter (complete)->
        Tansformer.enter(view.element, null, current.element, view.ctrl.transitIn, complete)

    api =
      init: (el)-> $element = el

      current: -> current

      popToView: (name, params)->
        ret = false
        if current and current.name is name
          #console.log "nav to same view", name
          ret = true

        else if view = _.find(stack, name:name)
          #console.log "view in stack", name, view.name
          removeView(current)
          while current = stack.pop()
            if current isnt view
              removeView(current)
            else
              break
          $animate.removeClass(current.element, 'stacked')
          current.scope.$broadcast('enterForeground')
          current.scope.$emit('$viewContentLoaded')
          ret = true

        if ret and not angular.equals(current.params, params)
          #console.log "param update", current.params, params
          current.params = params
          current.scope.$broadcast('$scopeUpdate')
        return ret

      changeView: (view, cached, params)->
        if not current
          current = view
          $element.after(view.element)
          #console.log "enter first view", view.name

        else if Nav.push()
          $animate.addClass(current.element, 'stacked')
          current.scope.$broadcast('enterBackground')
          stack.push(current)
          enterView(view, cached)
          #console.log "push view #{view.name}, stacked #{current.name}"
          current = view

        # Replace the current view
        else
          current.element.addClass('replaced')
          enterView(view, cached)
          removeView(current)
          #console.log "enter #{view.name}, replace #{current.name}"
          current = view

        if not cached
          current.scope.$broadcast('$scopeUpdate')
        else if not angular.equals(current.params, params)
          current.params = params
          current.scope.$broadcast('$scopeUpdate')

        current.scope.$emit('$viewContentLoaded')
        
  )

  .directive('cacheView', ($cacheFactory,  $route, ViewManager, Nav, ViewFactory)->
    restrict: 'E'
    terminal: true
    priority: 400
    transclude: 'element'
    link: (scope, $element, attr, ctrl, $transclude)->

      viewCache = $cacheFactory('viewCache')
      ViewManager.init($element)
      update = ->
        name = $route.current && $route.current.name
        if not name
          return
        # if view is in stack, popup to it
        if ViewManager.popToView(name, $route.current.params)
          #console.log "hit stack, return"
          return

        # Retrieve the view from cache
        view = viewCache.get(name)
        if view
          #console.log "hit cache"
          ViewManager.changeView(view, true, $route.current.params)
        else
          # scope maybe inherit from anthor view
          parentScope = scope
          if Nav.inherit()
            parentScope = ViewManager.current().scope
            #console.log "scope inherit from", parentScope
          newScope = parentScope.$new()

          # Create a new view
          current = $route.current
          clone = $transclude(newScope, ->)
          #console.log "Create a new view", name, current.params
          view = new ViewFactory(clone, name, newScope, current.params)
          ViewManager.changeView(view)

          #Cache the view
          if current.cache
            #console.log "Put to cache", name
            viewCache.put(name, view)
            view.cached = yes
            #To avoid scope be detached from element
            clone.remove = ()->
              for i in [0..@length-1]
                node = @[i]
                parent = node.parentNode
                parent?.removeChild(node)

        Nav.reset()
      update()
      scope.$on('$routeChangeSuccess', update)

  )
  .directive('cacheView', ($compile, $controller, $route)->
    restrict: 'E',
    priority: -400,
    link: (scope, $element)->
      current = $route.current
      locals = current.locals

      $element.html(locals.$template)

      link = $compile($element.contents())

      if (current.class)
        $element.addClass(current.class)
      
      if (current.controller)
        locals.$scope = scope
        locals.$element = $element
        scope.$controller = ctrl = $controller(current.controller, locals)
        ctrl.enter ?= (enter)-> enter()
        ctrl.leave ?= (leave)-> leave()

      link(scope)
  )