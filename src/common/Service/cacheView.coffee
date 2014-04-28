

angular.module( 'CacheView', [])
  .value('viewStack',
    []
  )
  .factory('ViewFactory', ($animate, Service)->
    class View
      constructor: (@element, @name, @scope) ->
        @ctrl = @scope.$controller

      leave: ->
        if @cached
          Service.disconnectScope(@scope)
        else
          @scope.$destroy()
        @element.addClass('replaced')
        @ctrl.leave @element

      enter: (after, parent)->
        if @cached
          Service.reconnectScope(@scope)
          @element.removeClass('replaced')
        @ctrl.enter @element, after, parent

      stack: ->
        $animate.addClass(@element, 'stacked')
        @scope.$broadcast('enterBackground')

      onPopup: ->
        $animate.removeClass(@element, 'stacked')
        @scope.$broadcast('enterForeground')
        @scope.$emit('$viewContentLoaded')

      update: (params, loaded)->

        if loaded
          #console.log "content just loaded"
          @scope.$emit('$viewContentLoaded')

        if not angular.equals(@params, params)
          #console.log "param update", @params, params
          @params = params
          @scope.$broadcast('$scopeUpdate')

    View
  )
  .factory('Nav', ($route, $location, viewStack, Service)->

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
        #throttle the Navigation by 500ms

        if viewStack.length
          ##console.log "just history.back"
          if Service.noRepeat('nav', 600)
            history.back()
        else if option
          ##console.log "no stack, go", option.name
          @go option

      go: (option)->

        #throttle the Navigation by 500ms
        return no unless Service.noRepeat('nav', 600)
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

        ##console.log "set url", $location.url(), replace


  )
  .factory('ViewManager', (Nav, $animate, Service, viewStack)->
    current = null
    $element = null
    stack = viewStack

    api =
      init: (el)-> $element = el

      current: -> current

      popToView: (name, params)->
        ret = false
        if current and current.name is name
          ##console.log "nav to same view", name
          ret = true

        else if view = _.find(stack, name:name)
          ##console.log "view in stack", name, view.name
          current.leave()
          while current = stack.pop()
            if current isnt view
              current.leave()
            else
              break
          current.onPopup()
          ret = true

        if ret then current.update(params)
        return ret

      changeView: (view, params)->
        if not current
          current = view
          $element.after(view.element)
          ##console.log "enter first view", view.name

        else if Nav.push()
          current.stack()
          stack.push(current)
          view.enter(current.element)
          ##console.log "push view #{view.name}, stacked #{current.name}"
          current = view

        # Replace the current view
        else
          view.enter(current.element)
          current.leave()
          ##console.log "enter #{view.name}, replace #{current.name}"
          current = view

        view.update(params, true)
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
          ##console.log "hit stack, return"
          return

        # Retrieve the view from cache
        view = viewCache.get(name)
        if view
          ##console.log "hit cache"
          ViewManager.changeView(view, $route.current.params)
        else
          # scope maybe inherit from anthor view
          parentScope = scope
          if Nav.inherit()
            parentScope = ViewManager.current().scope
            ##console.log "scope inherit from", parentScope
          newScope = parentScope.$new()
          angular.extend(newScope, Nav.data())

          # Create a new view
          current = $route.current
          clone = $transclude(newScope, ->)
          ##console.log "Create a new view", name, current.params
          view = new ViewFactory(clone, name, newScope)
          ViewManager.changeView(view, current.params)

          #Cache the view
          if current.cache
            ##console.log "Put to cache", name
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
  .factory('Tansformer', ($timeout, Transitor)->

    api =
      enter: (element, parent, after, transitInStyle, complete)->

        perform = Transitor.transIn(element, transitInStyle)
        #console.log "append view"
        if after
          after.after(element)
        else
          parent.append(element)
        perform complete

      leave: (element, transitOutStyle)->
        perform = Transitor.transOut(element, transitOutStyle)
        perform ->
          #console.log "remove view"
          element.remove()

  )
  .factory('ViewController', ($controller, Tansformer)->

    proto =
      #register child element transition
      register: (@transIn, @transOut)->
        #console.log "register child transition", @name

      unregister: ->
        #console.log "unregistered", @name
        @transIn = @transOut = null

      #Perform view element leave
      leave: (element)->
        leave = =>
          #Perform any animimation on view element
          Tansformer.leave(element, @$aniOut)
        #console.log "leave view", @name
        if @transOut
          #console.log "find child transOut"
          @transOut(leave)
        else
          #console.log "no child transOut, leave"
          leave()

      #Perform view element enter
      enter: (element, after, parent)->
        enter = (complete)=>
          #Perform any animimation on view element
          Tansformer.enter(element, parent, after, @$aniIn, complete)
        #console.log "enter view", @name
        if @transIn
          #console.log "find child transIn"
          enter @transIn()
        else
          enter()
        #enter(@transIn?())

    (name, locals, adds)->
      ctrl = $controller(name, locals)
      ctrl.name = name
      angular.extend(ctrl, proto, adds)
      #Not work, this is the same object in proto
      #ctrl.__proto__ = proto
  )
  .directive('cacheView', ($compile, ViewController, $route)->
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
        scope.$controller = ctrl = ViewController(current.controller, locals, current.extends)

      link(scope)
  )