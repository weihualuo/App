
//ionic.js
// Create namespaces
//
window.ionic = {
    controllers: {},
    views: {},
    version: '{{ VERSION }}'
};

// ionic.utils.js
(function(ionic) {

    /* for nextUid() function below */
    var uid = ['0','0','0'];

    /**
     * Various utilities used throughout Ionic
     *
     * Some of these are adopted from underscore.js and backbone.js, both also MIT licensed.
     */
    ionic.Utils = {

        arrayMove: function (arr, old_index, new_index) {
            if (new_index >= arr.length) {
                var k = new_index - arr.length;
                while ((k--) + 1) {
                    arr.push(undefined);
                }
            }
            arr.splice(new_index, 0, arr.splice(old_index, 1)[0]);
            return arr;
        },

        /**
         * Return a function that will be called with the given context
         */
        proxy: function(func, context) {
            var args = Array.prototype.slice.call(arguments, 2);
            return function() {
                return func.apply(context, args.concat(Array.prototype.slice.call(arguments)));
            };
        },

        /**
         * Only call a function once in the given interval.
         *
         * @param func {Function} the function to call
         * @param wait {int} how long to wait before/after to allow function calls
         * @param immediate {boolean} whether to call immediately or after the wait interval
         */
        debounce: function(func, wait, immediate) {
            var timeout, args, context, timestamp, result;
            return function() {
                context = this;
                args = arguments;
                timestamp = new Date();
                var later = function() {
                    var last = (new Date()) - timestamp;
                    if (last < wait) {
                        timeout = setTimeout(later, wait - last);
                    } else {
                        timeout = null;
                        if (!immediate) result = func.apply(context, args);
                    }
                };
                var callNow = immediate && !timeout;
                if (!timeout) {
                    timeout = setTimeout(later, wait);
                }
                if (callNow) result = func.apply(context, args);
                return result;
            };
        },

        /**
         * Throttle the given fun, only allowing it to be
         * called at most every `wait` ms.
         */
        throttle: function(func, wait, options) {
            var context, args, result;
            var timeout = null;
            var previous = 0;
            options || (options = {});
            var later = function() {
                previous = options.leading === false ? 0 : Date.now();
                timeout = null;
                result = func.apply(context, args);
            };
            return function() {
                var now = Date.now();
                if (!previous && options.leading === false) previous = now;
                var remaining = wait - (now - previous);
                context = this;
                args = arguments;
                if (remaining <= 0) {
                    clearTimeout(timeout);
                    timeout = null;
                    previous = now;
                    result = func.apply(context, args);
                } else if (!timeout && options.trailing !== false) {
                    timeout = setTimeout(later, remaining);
                }
                return result;
            };
        },
        // Borrowed from Backbone.js's extend
        // Helper function to correctly set up the prototype chain, for subclasses.
        // Similar to `goog.inherits`, but uses a hash of prototype properties and
        // class properties to be extended.
        inherit: function(protoProps, staticProps) {
            var parent = this;
            var child;

            // The constructor function for the new subclass is either defined by you
            // (the "constructor" property in your `extend` definition), or defaulted
            // by us to simply call the parent's constructor.
            if (protoProps && protoProps.hasOwnProperty('constructor')) {
                child = protoProps.constructor;
            } else {
                child = function(){ return parent.apply(this, arguments); };
            }

            // Add static properties to the constructor function, if supplied.
            ionic.extend(child, parent, staticProps);

            // Set the prototype chain to inherit from `parent`, without calling
            // `parent`'s constructor function.
            var Surrogate = function(){ this.constructor = child; };
            Surrogate.prototype = parent.prototype;
            child.prototype = new Surrogate;

            // Add prototype properties (instance properties) to the subclass,
            // if supplied.
            if (protoProps) ionic.extend(child.prototype, protoProps);

            // Set a convenience property in case the parent's prototype is needed
            // later.
            child.__super__ = parent.prototype;

            return child;
        },

        // Extend adapted from Underscore.js
        extend: function(obj) {
            var args = Array.prototype.slice.call(arguments, 1);
            for(var i = 0; i < args.length; i++) {
                var source = args[i];
                if (source) {
                    for (var prop in source) {
                        obj[prop] = source[prop];
                    }
                }
            }
            return obj;
        },

        /**
         * A consistent way of creating unique IDs in angular. The ID is a sequence of alpha numeric
         * characters such as '012ABC'. The reason why we are not using simply a number counter is that
         * the number string gets longer over time, and it can also overflow, where as the nextId
         * will grow much slower, it is a string, and it will never overflow.
         *
         * @returns an unique alpha-numeric string
         */
        nextUid: function() {
            var index = uid.length;
            var digit;

            while(index) {
                index--;
                digit = uid[index].charCodeAt(0);
                if (digit == 57 /*'9'*/) {
                    uid[index] = 'A';
                    return uid.join('');
                }
                if (digit == 90  /*'Z'*/) {
                    uid[index] = '0';
                } else {
                    uid[index] = String.fromCharCode(digit + 1);
                    return uid.join('');
                }
            }
            uid.unshift('0');
            return uid.join('');
        }
    };

    // Bind a few of the most useful functions to the ionic scope
    ionic.inherit = ionic.Utils.inherit;
    ionic.extend = ionic.Utils.extend;
    ionic.throttle = ionic.Utils.throttle;
    ionic.proxy = ionic.Utils.proxy;
    ionic.debounce = ionic.Utils.debounce;

})(window.ionic);


/**
 * ion-events.js
 *
 * Author: Max Lynch <max@drifty.com>
 *
 * Framework events handles various mobile browser events, and
 * detects special events like tap/swipe/etc. and emits them
 * as custom events that can be used in an app.
 *
 * Portions lovingly adapted from github.com/maker/ratchet and github.com/alexgibson/tap.js - thanks guys!
 */

(function(ionic) {

    // Custom event polyfill
    if(!window.CustomEvent) {
        (function() {
            var CustomEvent;

            CustomEvent = function(event, params) {
                var evt;
                params = params || {
                    bubbles: false,
                    cancelable: false,
                    detail: undefined
                };
                try {
                    evt = document.createEvent("CustomEvent");
                    evt.initCustomEvent(event, params.bubbles, params.cancelable, params.detail);
                } catch (error) {
                    // fallback for browsers that don't support createEvent('CustomEvent')
                    evt = document.createEvent("Event");
                    for (var param in params) {
                        evt[param] = params[param];
                    }
                    evt.initEvent(event, params.bubbles, params.cancelable);
                }
                return evt;
            };

            CustomEvent.prototype = window.Event.prototype;

            window.CustomEvent = CustomEvent;
        })();
    }

    ionic.EventController = {
        VIRTUALIZED_EVENTS: ['tap', 'swipe', 'swiperight', 'swipeleft', 'drag', 'hold', 'release'],

        // Trigger a new event
        trigger: function(eventType, data, bubbles, cancelable) {
            var event = new CustomEvent(eventType, {
                detail: data,
                bubbles: !!bubbles,
                cancelable: !!cancelable
            });

            // Make sure to trigger the event on the given target, or dispatch it from
            // the window if we don't have an event target
            data && data.target && data.target.dispatchEvent(event) || window.dispatchEvent(event);
        },

        // Bind an event
        on: function(type, callback, element) {
            var e = element || window;

            // Bind a gesture if it's a virtual event
            for(var i = 0, j = this.VIRTUALIZED_EVENTS.length; i < j; i++) {
                if(type == this.VIRTUALIZED_EVENTS[i]) {
                    var gesture = new ionic.Gesture(element);
                    gesture.on(type, callback);
                    return gesture;
                }
            }

            // Otherwise bind a normal event
            e.addEventListener(type, callback);
        },

        off: function(type, callback, element) {
            element.removeEventListener(type, callback);
        },

        // Register for a new gesture event on the given element
        onGesture: function(type, callback, element) {
            var gesture = new ionic.Gesture(element);
            gesture.on(type, callback);
            return gesture;
        },

        // Unregister a previous gesture event
        offGesture: function(gesture, type, callback) {
            gesture.off(type, callback);
        },

        handlePopState: function(event) {
        },
    };


    // Map some convenient top-level functions for event handling
    ionic.on = function() { ionic.EventController.on.apply(ionic.EventController, arguments); };
    ionic.off = function() { ionic.EventController.off.apply(ionic.EventController, arguments); };
    ionic.trigger = ionic.EventController.trigger;//function() { ionic.EventController.trigger.apply(ionic.EventController.trigger, arguments); };
    ionic.onGesture = function() { return ionic.EventController.onGesture.apply(ionic.EventController.onGesture, arguments); };
    ionic.offGesture = function() { return ionic.EventController.offGesture.apply(ionic.EventController.offGesture, arguments); };

})(window.ionic);


//ionic.dom.js
(function(ionic) {

    var readyCallbacks = [],
        domReady = function() {
            for(var x=0; x<readyCallbacks.length; x++) {
                ionic.requestAnimationFrame(readyCallbacks[x]);
            }
            readyCallbacks = [];
            document.removeEventListener('DOMContentLoaded', domReady);
        };
    document.addEventListener('DOMContentLoaded', domReady);

    // From the man himself, Mr. Paul Irish.
    // The requestAnimationFrame polyfill
    // Put it on window just to preserve its context
    // without having to use .call
    window._rAF = (function(){
        return  window.requestAnimationFrame       ||
            window.webkitRequestAnimationFrame ||
            window.mozRequestAnimationFrame    ||
            function( callback ){
                window.setTimeout(callback, 16);
            };
    })();

    ionic.DomUtil = {
        //Call with proper context
        requestAnimationFrame: function(cb) {
            window._rAF(cb);
        },

        /*
         * When given a callback, if that callback is called 100 times between
         * animation frames, Throttle will make it only call the last of 100tha call
         *
         * It returns a function, which will then call the passed in callback.  The
         * passed in callback will receive the context the returned function is called with.
         *
         * @example
         *   this.setTranslateX = ionic.animationFrameThrottle(function(x) {
         *     this.el.style[ionic.CSS.TRANSFORM] = 'translate3d(' + x + 'px, 0, 0)';
         *   })
         */
        animationFrameThrottle: function(cb) {
            var args, isQueued, context;
            return function() {
                args = arguments;
                context = this;
                if (!isQueued) {
                    isQueued = true;
                    ionic.requestAnimationFrame(function() {
                        cb.apply(context, args);
                        isQueued = false;
                    });
                }
            };
        },

        /*
         * Find an element's offset, then add it to the offset of the parent
         * until we are at the direct child of parentEl
         * use-case: find scroll offset of any element within a scroll container
         */
        getPositionInParent: function(el) {
            return {
                left: el.offsetLeft,
                top: el.offsetTop
            };
        },

        ready: function(cb) {
            if(document.readyState === "complete") {
                ionic.requestAnimationFrame(cb);
            } else {
                readyCallbacks.push(cb);
            }
        },

        getTextBounds: function(textNode) {
            if(document.createRange) {
                var range = document.createRange();
                range.selectNodeContents(textNode);
                if(range.getBoundingClientRect) {
                    var rect = range.getBoundingClientRect();
                    if(rect) {
                        var sx = window.scrollX;
                        var sy = window.scrollY;

                        return {
                            top: rect.top + sy,
                            left: rect.left + sx,
                            right: rect.left + sx + rect.width,
                            bottom: rect.top + sy + rect.height,
                            width: rect.width,
                            height: rect.height
                        };
                    }
                }
            }
            return null;
        },

        getChildIndex: function(element, type) {
            if(type) {
                var ch = element.parentNode.children;
                var c;
                for(var i = 0, k = 0, j = ch.length; i < j; i++) {
                    c = ch[i];
                    if(c.nodeName && c.nodeName.toLowerCase() == type) {
                        if(c == element) {
                            return k;
                        }
                        k++;
                    }
                }
            }
            return Array.prototype.slice.call(element.parentNode.children).indexOf(element);
        },
        swapNodes: function(src, dest) {
            dest.parentNode.insertBefore(src, dest);
        },
        /**
         * {returns} the closest parent matching the className
         */
        getParentWithClass: function(e, className) {
            while(e.parentNode) {
                if(e.parentNode.classList && e.parentNode.classList.contains(className)) {
                    return e.parentNode;
                }
                e = e.parentNode;
            }
            return null;
        },
        /**
         * {returns} the closest parent or self matching the className
         */
        getParentOrSelfWithClass: function(e, className) {
            while(e) {
                if(e.classList && e.classList.contains(className)) {
                    return e;
                }
                e = e.parentNode;
            }
            return null;
        },

        rectContains: function(x, y, x1, y1, x2, y2) {
            if(x < x1 || x > x2) return false;
            if(y < y1 || y > y2) return false;
            return true;
        }
    };

    //Shortcuts
    ionic.requestAnimationFrame = ionic.DomUtil.requestAnimationFrame;
    ionic.animationFrameThrottle = ionic.DomUtil.animationFrameThrottle;
})(window.ionic);


//ionic.view.js
(function(ionic) {
    'use strict';
    ionic.views.View = function() {
        this.initialize.apply(this, arguments);
    };

    ionic.views.View.inherit = ionic.inherit;

    ionic.extend(ionic.views.View.prototype, {
        initialize: function() {}
    });

})(window.ionic);

