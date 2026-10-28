/*
 * ExamPageGuard.js: injected into every page (and every frame) before the page's own scripts run.
 *
 *  1. A page can never tell that the student switched to another window, tab or app: it is always
 *     visible and focused, and the events that would report otherwise never reach it.
 *  2. Copy, cut, paste and selecting text always work, whatever the page tries to do about it.
 *  3. A page can never stop the student from quitting: Cmd+Q is not something a page can cancel.
 *
 * Everything is wrapped so that a problem here can never break the page.
 */
(function () {
  'use strict';
  try {
    var define = function (target, property, descriptor) {
      try { Object.defineProperty(target, property, descriptor); } catch (e) {}
    };

    /* ---- 1. Always visible, always focused ---------------------------------------------------- */

    define(Document.prototype, 'hidden', { get: function () { return false; }, configurable: true });
    define(Document.prototype, 'webkitHidden', { get: function () { return false; }, configurable: true });
    define(Document.prototype, 'visibilityState', { get: function () { return 'visible'; }, configurable: true });
    define(Document.prototype, 'webkitVisibilityState', { get: function () { return 'visible'; }, configurable: true });
    define(Document.prototype, 'hasFocus', {
      value: function hasFocus() { return true; }, writable: true, configurable: true
    });

    // Only events aimed at the window or the document are swallowed: focus and blur of the page's own
    // elements (inputs, buttons, links) are untouched, so forms and keyboard navigation keep working.
    var swallowWindowEvent = function (event) {
      var target = event.target;
      if (target === window || target === document) {
        event.stopImmediatePropagation();
      } else if (event.type === 'mouseleave' && target === document.documentElement) {
        event.stopImmediatePropagation();
      }
    };
    ['blur', 'focus', 'visibilitychange', 'webkitvisibilitychange', 'mouseleave'].forEach(function (type) {
      // capturing, and registered before any page script can register anything
      window.addEventListener(type, swallowWindowEvent, true);
    });

    /* ---- 2. Copy, cut, paste and selecting always work ---------------------------------------- */

    var CLIPBOARD_EVENTS = {
      copy: 1, cut: 1, paste: 1, beforecopy: 1, beforecut: 1, beforepaste: 1, selectstart: 1
    };
    var KEY_EVENTS = { keydown: 1, keypress: 1, keyup: 1 };
    // c, v, x, a: clipboard and select all. q: quit
    var CLIPBOARD_KEYS = { c: 1, v: 1, x: 1, a: 1, q: 1, keyc: 1, keyv: 1, keyx: 1, keya: 1, keyq: 1 };

    var isProtected = function (event) {
      var type = event.type;
      if (CLIPBOARD_EVENTS[type] === 1) { return true; }
      if (KEY_EVENTS[type] === 1 && (event.metaKey || event.ctrlKey)) {
        return CLIPBOARD_KEYS[String(event.key).toLowerCase()] === 1 || CLIPBOARD_KEYS[String(event.code).toLowerCase()] === 1;
      }
      return false;
    };

    // The page asks to cancel the event: for these events the request is ignored.
    var originalPreventDefault = Event.prototype.preventDefault;
    define(Event.prototype, 'preventDefault', {
      value: function preventDefault() {
        if (isProtected(this)) { return; }
        return originalPreventDefault.apply(this, arguments);
      },
      writable: true, configurable: true
    });

    var returnValue = Object.getOwnPropertyDescriptor(Event.prototype, 'returnValue');
    if (returnValue && returnValue.set) {
      define(Event.prototype, 'returnValue', {
        get: returnValue.get,
        set: function (value) { if (isProtected(this)) { return; } returnValue.set.call(this, value); },
        configurable: true, enumerable: returnValue.enumerable
      });
    }

    // Handlers set from script ("element.onpaste = function () { return false; }"): "return false" cancels
    // the event, so the returned value is dropped for these events.
    var HANDLER_PROPERTIES = ['oncopy', 'oncut', 'onpaste', 'onbeforecopy', 'onbeforecut', 'onbeforepaste', 'onselectstart'];
    var wrapHandler = function (handler) {
      if (typeof handler !== 'function') { return handler; }
      return function () {
        var result = handler.apply(this, arguments);
        return result === false ? undefined : result;
      };
    };
    [typeof HTMLElement !== 'undefined' ? HTMLElement.prototype : null,
     typeof Document !== 'undefined' ? Document.prototype : null,
     typeof Window !== 'undefined' ? Window.prototype : null,
     window].forEach(function (target) {
      if (!target) { return; }
      HANDLER_PROPERTIES.forEach(function (property) {
        var descriptor = Object.getOwnPropertyDescriptor(target, property);
        if (descriptor && descriptor.set && descriptor.configurable) {
          define(target, property, {
            get: descriptor.get,
            set: function (value) { descriptor.set.call(this, wrapHandler(value)); },
            configurable: true, enumerable: descriptor.enumerable
          });
        }
      });
    });

    // A page that empties the field right after something was pasted into it ("anti-paste") doesn't succeed:
    // setting a pasted-into field to nothing within a quarter of a second of the paste is ignored.
    var lastPaste = { target: null, time: 0 };
    document.addEventListener('paste', function (event) { lastPaste.target = event.target; lastPaste.time = Date.now(); }, true);
    ['HTMLInputElement', 'HTMLTextAreaElement'].forEach(function (name) {
      var prototype = window[name] && window[name].prototype;
      var descriptor = prototype && Object.getOwnPropertyDescriptor(prototype, 'value');
      if (descriptor && descriptor.set && descriptor.configurable) {
        define(prototype, 'value', {
          get: descriptor.get,
          set: function (value) {
            if ((value === '' || value === null) && this === lastPaste.target && Date.now() - lastPaste.time < 250) { return; }
            descriptor.set.call(this, value);
          },
          configurable: true, enumerable: descriptor.enumerable
        });
      }
    });

    // Handlers written in the page's HTML ("<input onpaste='return false'>") are removed as they appear.
    var removeInlineHandlers = function (root) {
      if (!root || root.nodeType !== 1) { return; }
      HANDLER_PROPERTIES.forEach(function (name) { if (root.hasAttribute(name)) { root.removeAttribute(name); } });
      if (root.querySelectorAll) {
        var selector = HANDLER_PROPERTIES.map(function (name) { return '[' + name + ']'; }).join(',');
        var found = root.querySelectorAll(selector);
        for (var i = 0; i < found.length; i++) {
          HANDLER_PROPERTIES.forEach(function (name) { found[i].removeAttribute(name); });
        }
      }
    };

    // Text can always be selected (and therefore copied)
    var styleAdded = false;
    var addSelectableStyle = function () {
      if (styleAdded) { return; }
      var host = document.head || document.documentElement;
      if (!host) { return; }
      var style = document.createElement('style');
      // everything except things that are dragged or pressed: selecting text on those would get in the way
      style.textContent = '*:not([draggable="true"]):not([draggable="true"] *):not(button):not(button *):not([role="button"]):not([role="button"] *)'
        + ':not(select):not(summary):not(input[type="range"]):not(.ui-sortable-handle):not(.ui-draggable)'
        + '{-webkit-user-select:text!important;user-select:text!important;}';
      host.appendChild(style);
      styleAdded = true;
    };

    new MutationObserver(function (mutations) {
      addSelectableStyle();
      for (var i = 0; i < mutations.length; i++) {
        var mutation = mutations[i];
        if (mutation.type === 'attributes') {
          mutation.target.removeAttribute(mutation.attributeName);
        } else {
          for (var j = 0; j < mutation.addedNodes.length; j++) { removeInlineHandlers(mutation.addedNodes[j]); }
        }
      }
    }).observe(document, { attributes: true, attributeFilter: HANDLER_PROPERTIES, childList: true, subtree: true });

    document.addEventListener('DOMContentLoaded', function () {
      addSelectableStyle();
      removeInlineHandlers(document.documentElement);
    }, true);
  } catch (e) { /* never break the page */ }
})();
