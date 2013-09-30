/*
 * JavaScript Custom Forms Module
 */
jcf = {
  // global options
  modules: {},
  plugins: {},
  baseOptions: {
    useNativeDropOnMobileDevices: true,
    unselectableClass:'jcf-unselectable',
    labelActiveClass:'jcf-label-active',
    labelDisabledClass:'jcf-label-disabled',
    classPrefix: 'jcf-class-',
    hiddenClass:'jcf-hidden',
    focusClass:'jcf-focus',
    wrapperTag: 'div'
  },
  // replacer function
  customForms: {
    setOptions: function(obj) {
      for(var p in obj) {
        if(obj.hasOwnProperty(p) && typeof obj[p] === 'object') {
          jcf.lib.extend(jcf.modules[p].prototype.defaultOptions, obj[p]);
        }
      }
    },
    replaceAll: function(scope) {
      scope = scope || document;
      for(var k in jcf.modules) {
        var els = jcf.lib.queryBySelector(jcf.modules[k].prototype.selector, scope);
        for(var i = 0; i<els.length; i++) {
          if(els[i].jcf) {
            // refresh form element state
            els[i].jcf.refreshState();
          } else {
            // replace form element
            if(!jcf.lib.hasClass(els[i], 'default') && jcf.modules[k].prototype.checkElement(els[i])) {
              new jcf.modules[k]({
                replaces:els[i]
              });
            }
          }
        }
      }
    },
    refreshAll: function() {
      for(var k in jcf.modules) {
        var els = jcf.lib.queryBySelector(jcf.modules[k].prototype.selector);
        for(var i = 0; i<els.length; i++) {
          if(els[i].jcf) {
            // refresh form element state
            els[i].jcf.refreshState();
          }
        }
      }
    },
    refreshElement: function(obj) {
      if(obj && obj.jcf) {
        obj.jcf.refreshState();
      }
    },
    destroyAll: function() {
      for(var k in jcf.modules) {
        var els = jcf.lib.queryBySelector(jcf.modules[k].prototype.selector);
        for(var i = 0; i<els.length; i++) {
          if(els[i].jcf) {
            els[i].jcf.destroy();
          }
        }
      }
    }
  },
  // detect device type
  isTouchDevice: (function() {
    try {
      return ('ontouchstart' in window) || window.DocumentTouch && document instanceof DocumentTouch;
    } catch (e) {
      return false;
    }
  }()),
  // define base module
  setBaseModule: function(obj) {
    jcf.customControl = function(opt){
      this.options = jcf.lib.extend({}, jcf.baseOptions, this.defaultOptions, opt);
      this.init();
    };
    for(var p in obj) {
      jcf.customControl.prototype[p] = obj[p];
    }
  },
  // add module to jcf.modules
  addModule: function(obj) {
    if(obj.name){
      // create new module proto class
      jcf.modules[obj.name] = function(){
        jcf.modules[obj.name].superclass.constructor.apply(this, arguments);
      };
      jcf.lib.inherit(jcf.modules[obj.name], jcf.customControl);
      for(var p in obj) {
        jcf.modules[obj.name].prototype[p] = obj[p];
      }
      // on create module
      jcf.modules[obj.name].prototype.onCreateModule();
      // make callback for exciting modules
      for(var mod in jcf.modules) {
        if(jcf.modules[mod] != jcf.modules[obj.name]) {
          jcf.modules[mod].prototype.onModuleAdded(jcf.modules[obj.name]);
        }
      }
    }
  },
  // add plugin to jcf.plugins
  addPlugin: function(obj) {
    if(obj && obj.name) {
      jcf.plugins[obj.name] = function() {
        this.init.apply(this, arguments);
      };
      for(var p in obj) {
        jcf.plugins[obj.name].prototype[p] = obj[p];
      }
    }
  },
  // miscellaneous init
  init: function(){
    if(navigator.msPointerEnabled) {
      this.eventPress = 'MSPointerDown';
      this.eventMove = 'MSPointerMove';
      this.eventRelease = 'MSPointerUp';
    } else {
      this.eventPress = this.isTouchDevice ? 'touchstart' : 'mousedown';
      this.eventMove = this.isTouchDevice ? 'touchmove' : 'mousemove';
      this.eventRelease = this.isTouchDevice ? 'touchend' : 'mouseup';
    }

    // init jcf styles
    setTimeout(function(){
      jcf.lib.domReady(function(){
        jcf.initStyles();
      });
    },1);
    return this;
  },
  initStyles: function() {
    // create <style> element and rules
    var head = document.getElementsByTagName('head')[0],
      style = document.createElement('style'),
      rules = document.createTextNode('.'+jcf.baseOptions.unselectableClass+'{'+
        '-moz-user-select:none;'+
        '-webkit-tap-highlight-color:rgba(255,255,255,0);'+
        '-webkit-user-select:none;'+
        'user-select:none;'+
      '}');
    
    // append style element
    style.type = 'text/css';
    if(style.styleSheet) {
      style.styleSheet.cssText = rules.nodeValue;
    } else {
      style.appendChild(rules);
    }
    head.appendChild(style);
  }
}.init();

/*
 * Custom Form Control prototype
 */
jcf.setBaseModule({
  init: function(){
    if(this.options.replaces) {
      this.realElement = this.options.replaces;
      this.realElement.jcf = this;
      this.replaceObject();
    }
  },
  defaultOptions: {
    // default module options (will be merged with base options)
  },
  checkElement: function(el){
    return true; // additional check for correct form element
  },
  replaceObject: function(){
    this.createWrapper();
    this.attachEvents();
    this.fixStyles();
    this.setupWrapper();
  },
  createWrapper: function(){
    this.fakeElement = jcf.lib.createElement(this.options.wrapperTag);
    this.labelFor = jcf.lib.getLabelFor(this.realElement);
    jcf.lib.disableTextSelection(this.fakeElement);
    jcf.lib.addClass(this.fakeElement, jcf.lib.getAllClasses(this.realElement.className, this.options.classPrefix));
    jcf.lib.addClass(this.realElement, jcf.baseOptions.hiddenClass);
  },
  attachEvents: function(){
    jcf.lib.event.add(this.realElement, 'focus', this.onFocusHandler, this);
    jcf.lib.event.add(this.realElement, 'blur', this.onBlurHandler, this);
    jcf.lib.event.add(this.fakeElement, 'click', this.onFakeClick, this);
    jcf.lib.event.add(this.fakeElement, jcf.eventPress, this.onFakePressed, this);
    jcf.lib.event.add(this.fakeElement, jcf.eventRelease, this.onFakeReleased, this);

    if(this.labelFor) {
      this.labelFor.jcf = this;
      jcf.lib.event.add(this.labelFor, 'click', this.onFakeClick, this);
      jcf.lib.event.add(this.labelFor, jcf.eventPress, this.onFakePressed, this);
      jcf.lib.event.add(this.labelFor, jcf.eventRelease, this.onFakeReleased, this);
    }
  },
  fixStyles: function() {
    // hide mobile webkit tap effect
    if(jcf.isTouchDevice) {
      var tapStyle = 'rgba(255,255,255,0)';
      this.realElement.style.webkitTapHighlightColor = tapStyle;
      this.fakeElement.style.webkitTapHighlightColor = tapStyle;
      if(this.labelFor) {
        this.labelFor.style.webkitTapHighlightColor = tapStyle;
      }
    }
  },
  setupWrapper: function(){
    // implement in subclass
  },
  refreshState: function(){
    // implement in subclass
  },
  destroy: function() {
    if(this.fakeElement && this.fakeElement.parentNode) {
      this.fakeElement.parentNode.removeChild(this.fakeElement);
    }
    jcf.lib.removeClass(this.realElement, jcf.baseOptions.hiddenClass);
    this.realElement.jcf = null;
  },
  onFocus: function(){
    // emulated focus event
    jcf.lib.addClass(this.fakeElement,this.options.focusClass);
  },
  onBlur: function(cb){
    // emulated blur event
    jcf.lib.removeClass(this.fakeElement,this.options.focusClass);
  },
  onFocusHandler: function() {
    // handle focus loses
    if(this.focused) return;
    this.focused = true;
    
    // handle touch devices also
    if(jcf.isTouchDevice) {
      if(jcf.focusedInstance && jcf.focusedInstance.realElement != this.realElement) {
        jcf.focusedInstance.onBlur();
        jcf.focusedInstance.realElement.blur();
      }
      jcf.focusedInstance = this;
    }
    this.onFocus.apply(this, arguments);
  },
  onBlurHandler: function() {
    // handle focus loses
    if(!this.pressedFlag) {
      this.focused = false;
      this.onBlur.apply(this, arguments);
    }
  },
  onFakeClick: function(){
    if(jcf.isTouchDevice) {
      this.onFocus();
    } else if(!this.realElement.disabled) {
      this.realElement.focus();
    }
  },
  onFakePressed: function(e){
    this.pressedFlag = true;
  },
  onFakeReleased: function(){
    this.pressedFlag = false;
  },
  onCreateModule: function(){
    // implement in subclass
  },
  onModuleAdded: function(module) {
    // implement in subclass
  },
  onControlReady: function() {
    // implement in subclass
  }
});

/*
 * JCF Utility Library
 */
jcf.lib = {
  bind: function(func, scope){
    return function() {
      return func.apply(scope, arguments);
    }
  },
  browser: (function() {
    var ua = navigator.userAgent.toLowerCase(), res = {},
    match = /(webkit)[ \/]([\w.]+)/.exec(ua) || /(opera)(?:.*version)?[ \/]([\w.]+)/.exec(ua) ||
        /(msie) ([\w.]+)/.exec(ua) || ua.indexOf("compatible") < 0 && /(mozilla)(?:.*? rv:([\w.]+))?/.exec(ua) || [];
    res[match[1]] = true;
    res.version = match[2] || "0";
    res.safariMac = ua.indexOf('mac') != -1 && ua.indexOf('safari') != -1;
    return res;
  })(),
  getOffset: function (obj) {
    if (obj.getBoundingClientRect && !navigator.msPointerEnabled) {
      var scrollLeft = window.pageXOffset || document.documentElement.scrollLeft || document.body.scrollLeft;
      var scrollTop = window.pageYOffset || document.documentElement.scrollTop || document.body.scrollTop;
      var clientLeft = document.documentElement.clientLeft || document.body.clientLeft || 0;
      var clientTop = document.documentElement.clientTop || document.body.clientTop || 0;
      return {
        top:Math.round(obj.getBoundingClientRect().top + scrollTop - clientTop),
        left:Math.round(obj.getBoundingClientRect().left + scrollLeft - clientLeft)
      }
    } else {
      var posLeft = 0, posTop = 0;
      while (obj.offsetParent) {posLeft += obj.offsetLeft; posTop += obj.offsetTop; obj = obj.offsetParent;}
      return {top:posTop,left:posLeft};
    }
  },
  getScrollTop: function() {
    return window.pageYOffset || document.documentElement.scrollTop;
  },
  getScrollLeft: function() {
    return window.pageXOffset || document.documentElement.scrollLeft;
  },
  getWindowWidth: function(){
    return document.compatMode=='CSS1Compat' ? document.documentElement.clientWidth : document.body.clientWidth;
  },
  getWindowHeight: function(){
    return document.compatMode=='CSS1Compat' ? document.documentElement.clientHeight : document.body.clientHeight;
  },
  getStyle: function(el, prop) {
    if (document.defaultView && document.defaultView.getComputedStyle) {
      return document.defaultView.getComputedStyle(el, null)[prop];
    } else if (el.currentStyle) {
      return el.currentStyle[prop];
    } else {
      return el.style[prop];
    }
  },
  getParent: function(obj, selector) {
    while(obj.parentNode && obj.parentNode != document.body) {
      if(obj.parentNode.tagName.toLowerCase() == selector.toLowerCase()) {
        return obj.parentNode;
      }
      obj = obj.parentNode;
    }
    return false;
  },
  isParent: function(child, parent) {
    while(child.parentNode) {
      if(child.parentNode === parent) {
        return true;
      }
      child = child.parentNode;
    }
    return false;
  },
  getLabelFor: function(object) {
    if(jcf.lib.getParent(object,'label')) {
      return object.parentNode;
    } else if(object.id) {
      return jcf.lib.queryBySelector('label[for="' + object.id + '"]')[0];
    }
  },
  disableTextSelection: function(el){
    if (typeof el.onselectstart !== 'undefined') {
      el.onselectstart = function() {return false};
    } else if(window.opera) {
      el.setAttribute('unselectable', 'on');
    } else {
      jcf.lib.addClass(el, jcf.baseOptions.unselectableClass);
    }
  },
  enableTextSelection: function(el) {
    if (typeof el.onselectstart !== 'undefined') {
      el.onselectstart = null;
    } else if(window.opera) {
      el.removeAttribute('unselectable');
    } else {
      jcf.lib.removeClass(el, jcf.baseOptions.unselectableClass);
    }
  },
  queryBySelector: function(selector, scope){
    return this.getElementsBySelector(selector, scope);
  },
  prevSibling: function(node) {
    while(node = node.previousSibling) if(node.nodeType == 1) break;
    return node;
  },
  nextSibling: function(node) {
    while(node = node.nextSibling) if(node.nodeType == 1) break;
    return node;
  },
  fireEvent: function(element,event) {
    if(element.dispatchEvent){
      var evt = document.createEvent('HTMLEvents');
      evt.initEvent(event, true, true );
      return !element.dispatchEvent(evt);
    }else if(document.createEventObject){
      var evt = document.createEventObject();
      return element.fireEvent('on'+event,evt);
    }
  },
  isParent: function(p, c) {
    while(c.parentNode) {
      if(p == c) {
        return true;
      }
      c = c.parentNode;
    }
    return false;
  },
  inherit: function(Child, Parent) {
    var F = function() { }
    F.prototype = Parent.prototype
    Child.prototype = new F()
    Child.prototype.constructor = Child
    Child.superclass = Parent.prototype
  },
  extend: function(obj) {
    for(var i = 1; i < arguments.length; i++) {
      for(var p in arguments[i]) {
        if(arguments[i].hasOwnProperty(p)) {
          obj[p] = arguments[i][p];
        }
      }
    }
    return obj;
  },
  hasClass: function (obj,cname) {
    return (obj.className ? obj.className.match(new RegExp('(\\s|^)'+cname+'(\\s|$)')) : false);
  },
  addClass: function (obj,cname) {
    if (!this.hasClass(obj,cname)) obj.className += (!obj.className.length || obj.className.charAt(obj.className.length - 1) === ' ' ? '' : ' ') + cname;
  },
  removeClass: function (obj,cname) {
    if (this.hasClass(obj,cname)) obj.className=obj.className.replace(new RegExp('(\\s|^)'+cname+'(\\s|$)'),' ').replace(/\s+$/, '');
  },
  toggleClass: function(obj, cname, condition) {
    if(condition) this.addClass(obj, cname); else this.removeClass(obj, cname);
  },
  createElement: function(tagName, options) {
    var el = document.createElement(tagName);
    for(var p in options) {
      if(options.hasOwnProperty(p)) {
        switch (p) {
          case 'class': el.className = options[p]; break;
          case 'html': el.innerHTML = options[p]; break;
          case 'style': this.setStyles(el, options[p]); break;
          default: el.setAttribute(p, options[p]);
        }
      }
    }
    return el;
  },
  setStyles: function(el, styles) {
    for(var p in styles) {
      if(styles.hasOwnProperty(p)) {
        switch (p) {
          case 'float': el.style.cssFloat = styles[p]; break;
          case 'opacity': el.style.filter = 'progid:DXImageTransform.Microsoft.Alpha(opacity='+styles[p]*100+')'; el.style.opacity = styles[p]; break;
          default: el.style[p] = (typeof styles[p] === 'undefined' ? 0 : styles[p]) + (typeof styles[p] === 'number' ? 'px' : '');
        }
      }
    }
    return el;
  },
  getInnerWidth: function(el) {
    return el.offsetWidth - (parseInt(this.getStyle(el,'paddingLeft')) || 0) - (parseInt(this.getStyle(el,'paddingRight')) || 0);
  },
  getInnerHeight: function(el) {
    return el.offsetHeight - (parseInt(this.getStyle(el,'paddingTop')) || 0) - (parseInt(this.getStyle(el,'paddingBottom')) || 0);
  },
  getAllClasses: function(cname, prefix, skip) {
    if(!skip) skip = '';
    if(!prefix) prefix = '';
    return cname ? cname.replace(new RegExp('(\\s|^)'+skip+'(\\s|$)'),' ').replace(/[\s]*([\S]+)+[\s]*/gi,prefix+"$1 ") : '';
  },
  getElementsBySelector: function(selector, scope) {
    if(typeof document.querySelectorAll === 'function') {
      return (scope || document).querySelectorAll(selector);
    }
    var selectors = selector.split(',');
    var resultList = [];
    for(var s = 0; s < selectors.length; s++) {
      var currentContext = [scope || document];
      var tokens = selectors[s].replace(/^\s+/,'').replace(/\s+$/,'').split(' ');
      for (var i = 0; i < tokens.length; i++) {
        token = tokens[i].replace(/^\s+/,'').replace(/\s+$/,'');
        if (token.indexOf('#') > -1) {
          var bits = token.split('#'), tagName = bits[0], id = bits[1];
          var element = document.getElementById(id);
          if (tagName && element.nodeName.toLowerCase() != tagName) {
            return [];
          }
          currentContext = [element];
          continue;
        }
        if (token.indexOf('.') > -1) {
          var bits = token.split('.'), tagName = bits[0] || '*', className = bits[1], found = [], foundCount = 0;
          for (var h = 0; h < currentContext.length; h++) {
            var elements;
            if (tagName == '*') {
              elements = currentContext[h].getElementsByTagName('*');
            } else {
              elements = currentContext[h].getElementsByTagName(tagName);
            }
            for (var j = 0; j < elements.length; j++) {
              found[foundCount++] = elements[j];
            }
          }
          currentContext = [];
          var currentContextIndex = 0;
          for (var k = 0; k < found.length; k++) {
            if (found[k].className && found[k].className.match(new RegExp('(\\s|^)'+className+'(\\s|$)'))) {
              currentContext[currentContextIndex++] = found[k];
            }
          }
          continue;
        }
        if (token.match(/^(\w*)\[(\w+)([=~\|\^\$\*]?)=?"?([^\]"]*)"?\]$/)) {
          var tagName = RegExp.$1 || '*', attrName = RegExp.$2, attrOperator = RegExp.$3, attrValue = RegExp.$4;
          if(attrName.toLowerCase() == 'for' && this.browser.msie && this.browser.version < 8) {
            attrName = 'htmlFor';
          }
          var found = [], foundCount = 0;
          for (var h = 0; h < currentContext.length; h++) {
            var elements;
            if (tagName == '*') {
              elements = currentContext[h].getElementsByTagName('*');
            } else {
              elements = currentContext[h].getElementsByTagName(tagName);
            }
            for (var j = 0; elements[j]; j++) {
              found[foundCount++] = elements[j];
            }
          }
          currentContext = [];
          var currentContextIndex = 0, checkFunction;
          switch (attrOperator) {
            case '=': checkFunction = function(e) { return (e.getAttribute(attrName) == attrValue) }; break;
            case '~': checkFunction = function(e) { return (e.getAttribute(attrName).match(new RegExp('(\\s|^)'+attrValue+'(\\s|$)'))) }; break;
            case '|': checkFunction = function(e) { return (e.getAttribute(attrName).match(new RegExp('^'+attrValue+'-?'))) }; break;
            case '^': checkFunction = function(e) { return (e.getAttribute(attrName).indexOf(attrValue) == 0) }; break;
            case '$': checkFunction = function(e) { return (e.getAttribute(attrName).lastIndexOf(attrValue) == e.getAttribute(attrName).length - attrValue.length) }; break;
            case '*': checkFunction = function(e) { return (e.getAttribute(attrName).indexOf(attrValue) > -1) }; break;
            default : checkFunction = function(e) { return e.getAttribute(attrName) };
          }
          currentContext = [];
          var currentContextIndex = 0;
          for (var k = 0; k < found.length; k++) {
            if (checkFunction(found[k])) {
              currentContext[currentContextIndex++] = found[k];
            }
          }
          continue;
        }
        tagName = token;
        var found = [], foundCount = 0;
        for (var h = 0; h < currentContext.length; h++) {
          var elements = currentContext[h].getElementsByTagName(tagName);
          for (var j = 0; j < elements.length; j++) {
            found[foundCount++] = elements[j];
          }
        }
        currentContext = found;
      }
      resultList = [].concat(resultList,currentContext);
    }
    return resultList;
  },
  scrollSize: (function(){
    var content, hold, sizeBefore, sizeAfter;
    function buildSizer(){
      if(hold) removeSizer();
      content = document.createElement('div');
      hold = document.createElement('div');
      hold.style.cssText = 'position:absolute;overflow:hidden;width:100px;height:100px';
      hold.appendChild(content);
      document.body.appendChild(hold);
    }
    function removeSizer(){
      document.body.removeChild(hold);
      hold = null;
    }
    function calcSize(vertical) {
      buildSizer();
      content.style.cssText = 'height:'+(vertical ? '100%' : '200px');
      sizeBefore = (vertical ? content.offsetHeight : content.offsetWidth);
      hold.style.overflow = 'scroll'; content.innerHTML = 1;
      sizeAfter = (vertical ? content.offsetHeight : content.offsetWidth);
      if(vertical && hold.clientHeight) sizeAfter = hold.clientHeight;
      removeSizer();
      return sizeBefore - sizeAfter;
    }
    return {
      getWidth:function(){
        return calcSize(false);
      },
      getHeight:function(){
        return calcSize(true)
      }
    }
  }()),
  domReady: function (handler){
    var called = false
    function ready() {
      if (called) return;
      called = true;
      handler();
    }
    if (document.addEventListener) {
      document.addEventListener("DOMContentLoaded", ready, false);
    } else if (document.attachEvent) {
      if (document.documentElement.doScroll && window == window.top) {
        function tryScroll(){
          if (called) return
          if (!document.body) return
          try {
            document.documentElement.doScroll("left")
            ready()
          } catch(e) {
            setTimeout(tryScroll, 0)
          }
        }
        tryScroll()
      }
      document.attachEvent("onreadystatechange", function(){
        if (document.readyState === "complete") {
          ready()
        }
      })
    }
    if (window.addEventListener) window.addEventListener('load', ready, false)
    else if (window.attachEvent) window.attachEvent('onload', ready)
  },
  event: (function(){
    var guid = 0;
    function fixEvent(e) {
      e = e || window.event;
      if (e.isFixed) {
        return e;
      }
      e.isFixed = true; 
      e.preventDefault = e.preventDefault || function(){this.returnValue = false}
      e.stopPropagation = e.stopPropagaton || function(){this.cancelBubble = true}
      if (!e.target) {
        e.target = e.srcElement
      }
      if (!e.relatedTarget && e.fromElement) {
        e.relatedTarget = e.fromElement == e.target ? e.toElement : e.fromElement;
      }
      if (e.pageX == null && e.clientX != null) {
        var html = document.documentElement, body = document.body;
        e.pageX = e.clientX + (html && html.scrollLeft || body && body.scrollLeft || 0) - (html.clientLeft || 0);
        e.pageY = e.clientY + (html && html.scrollTop || body && body.scrollTop || 0) - (html.clientTop || 0);
      }
      if (!e.which && e.button) {
        e.which = e.button & 1 ? 1 : (e.button & 2 ? 3 : (e.button & 4 ? 2 : 0));
      }
      if(e.type === "DOMMouseScroll" || e.type === 'mousewheel') {
        e.mWheelDelta = 0;
        if (e.wheelDelta) {
          e.mWheelDelta = e.wheelDelta/120;
        } else if (e.detail) {
          e.mWheelDelta = -e.detail/3;
        }
      }
      return e;
    }
    function commonHandle(event, customScope) {
      event = fixEvent(event);
      var handlers = this.events[event.type];
      for (var g in handlers) {
        var handler = handlers[g];
        var ret = handler.call(customScope || this, event);
        if (ret === false) {
          event.preventDefault()
          event.stopPropagation()
        }
      }
    }
    var publicAPI = {
      add: function(elem, type, handler, forcedScope) {
        if (elem.setInterval && (elem != window && !elem.frameElement)) {
          elem = window;
        }
        if (!handler.guid) {
          handler.guid = ++guid;
        }
        if (!elem.events) {
          elem.events = {};
          elem.handle = function(event) {
            return commonHandle.call(elem, event);
          }
        }
        if (!elem.events[type]) {
          elem.events[type] = {};
          if (elem.addEventListener) elem.addEventListener(type, elem.handle, false);
          else if (elem.attachEvent) elem.attachEvent("on" + type, elem.handle);
          if(type === 'mousewheel') {
            publicAPI.add(elem, 'DOMMouseScroll', handler, forcedScope);
          }
        }
        var fakeHandler = jcf.lib.bind(handler, forcedScope);
        fakeHandler.guid = handler.guid;
        elem.events[type][handler.guid] = forcedScope ? fakeHandler : handler;
      },
      remove: function(elem, type, handler) {
        var handlers = elem.events && elem.events[type];
        if (!handlers) return;
        delete handlers[handler.guid];
        for(var any in handlers) return;
        if (elem.removeEventListener) elem.removeEventListener(type, elem.handle, false);
        else if (elem.detachEvent) elem.detachEvent("on" + type, elem.handle);
        delete elem.events[type];
        for (var any in elem.events) return;
        try {
          delete elem.handle;
          delete elem.events;
        } catch(e) {
          if(elem.removeAttribute) {
            elem.removeAttribute("handle");
            elem.removeAttribute("events");
          }
        }
        if(type === 'mousewheel') {
          publicAPI.remove(elem, 'DOMMouseScroll', handler);
        }
      }
    }
    return publicAPI;
  }())
}

/*
// custom select module
jcf.addModule({
  name:'select',
  selector:'select',
  defaultOptions: {
    hideDropOnScroll: true,
    showNativeDrop: false,
    handleDropPosition: false,
    selectDropPosition: 'bottom', // or 'top'
    wrapperClass:'select-area',
    focusClass:'select-focus',
    dropActiveClass:'select-active',
    selectedClass:'item-selected',
    currentSelectedClass:'current-selected',
    disabledClass:'select-disabled',
    valueSelector:'span.center', 
    optGroupClass:'optgroup',
    openerSelector:'a.select-opener',   
    selectStructure:'<span class="left"></span><span class="center"></span><a class="select-opener"></a>',
    classPrefix:'select-',
    dropMaxHeight: 200,
    dropFlippedClass: 'select-options-flipped',
    dropHiddenClass:'options-hidden',
    dropScrollableClass:'options-overflow',
    dropClass:'select-options',
    dropClassPrefix:'drop-',
    dropStructure:'<div class="drop-holder"><div class="drop-list"></div></div>',
    dropSelector:'div.drop-list'
  },
  checkElement: function(el){
    return (!el.size && !el.multiple);
  },
  setupWrapper: function(){
    jcf.lib.addClass(this.fakeElement, this.options.wrapperClass);
    this.realElement.parentNode.insertBefore(this.fakeElement, this.realElement);
    this.fakeElement.innerHTML = this.options.selectStructure;
    this.fakeElement.style.width = (this.realElement.offsetWidth > 0 ? this.realElement.offsetWidth + 'px' : 'auto');

    // show native drop if specified in options
    if(jcf.isTouchDevice && jcf.baseOptions.useNativeDropOnMobileDevices) {
      this.options.showNativeDrop = true;
    }
    if(this.options.showNativeDrop) {
      this.fakeElement.appendChild(this.realElement);
      jcf.lib.removeClass(this.realElement, this.options.hiddenClass);
      jcf.lib.setStyles(this.realElement, {
        top:0,
        left:0,
        margin:0,
        padding:0,
        opacity:0,
        border:'none',
        position:'absolute',
        width: jcf.lib.getInnerWidth(this.fakeElement) - 1,
        height: jcf.lib.getInnerHeight(this.fakeElement) - 1
      });
      jcf.lib.event.add(this.realElement, 'touchstart', function(){
        this.realElement.title = '';
      }, this)
    }
    
    // create select body
    this.opener = jcf.lib.queryBySelector(this.options.openerSelector, this.fakeElement)[0];
    this.valueText = jcf.lib.queryBySelector(this.options.valueSelector, this.fakeElement)[0];
    jcf.lib.disableTextSelection(this.valueText);
    this.opener.jcf = this;

    if(!this.options.showNativeDrop) {
      this.createDropdown();
      this.refreshState();
      this.onControlReady(this);
      this.hideDropdown(true);
    } else {
      this.refreshState();
    }
    this.addEvents();
  },
  addEvents: function(){
    if(this.options.showNativeDrop) {
      jcf.lib.event.add(this.realElement, 'click', this.onChange, this);
    } else {
      jcf.lib.event.add(this.fakeElement, 'click', this.toggleDropdown, this);
    }
    jcf.lib.event.add(this.realElement, 'change', this.onChange, this);
  },
  onFakeClick: function() {
    // do nothing (drop toggles by toggleDropdown method)
  },
  onFocus: function(){
    jcf.modules[this.name].superclass.onFocus.apply(this, arguments);
    if(!this.options.showNativeDrop) {
      // Mac Safari Fix
      if(jcf.lib.browser.safariMac) {
        this.realElement.setAttribute('size','2');
      }
      jcf.lib.event.add(this.realElement, 'keydown', this.onKeyDown, this);
      if(jcf.activeControl && jcf.activeControl != this) {
        jcf.activeControl.hideDropdown();
        jcf.activeControl = this;
      }
    }
  },
  onBlur: function(){
    if(!this.options.showNativeDrop) {
      // Mac Safari Fix
      if(jcf.lib.browser.safariMac) {
        this.realElement.removeAttribute('size');
      }
      if(!this.isActiveDrop() || !this.isOverDrop()) {
        jcf.modules[this.name].superclass.onBlur.apply(this);
        if(jcf.activeControl === this) jcf.activeControl = null;
        if(!jcf.isTouchDevice) {
          this.hideDropdown();
        }
      }
      jcf.lib.event.remove(this.realElement, 'keydown', this.onKeyDown);
    } else {
      jcf.modules[this.name].superclass.onBlur.apply(this);
    }
  },
  onChange: function() {
    this.refreshState();
  },
  onKeyDown: function(e){
    this.dropOpened = true;
    jcf.tmpFlag = true;
    setTimeout(function(){jcf.tmpFlag = false},100);
    var context = this;
    context.keyboardFix = true;
    setTimeout(function(){
      context.refreshState();
    },10);
    if(e.keyCode == 13) {
      context.toggleDropdown.apply(context);
      return false;
    }
  },
  onResizeWindow: function(e){
    if(this.isActiveDrop()) {
      this.hideDropdown();
    }
  },
  onScrollWindow: function(e){
    if(this.options.hideDropOnScroll) {
      this.hideDropdown();
    } else if(this.isActiveDrop()) {
      this.positionDropdown();
    }
  },
  onOptionClick: function(e){
    var opener = e.target && e.target.tagName && e.target.tagName.toLowerCase() == 'li' ? e.target : jcf.lib.getParent(e.target, 'li');
    if(opener) {
      this.dropOpened = true;
      this.realElement.selectedIndex = parseInt(opener.getAttribute('rel'));
      if(jcf.isTouchDevice) {
        this.onFocus();
      } else {
        this.realElement.focus();
      }
      this.refreshState();
      this.hideDropdown();
      jcf.lib.fireEvent(this.realElement, 'change');
    }
    return false;
  },
  onClickOutside: function(e){
    if(jcf.tmpFlag) {
      jcf.tmpFlag = false;
      return;
    }
    if(!jcf.lib.isParent(this.fakeElement, e.target) && !jcf.lib.isParent(this.selectDrop, e.target)) {
      this.hideDropdown();
    }
  },
  onDropHover: function(e){
    if(!this.keyboardFix) {
      this.hoverFlag = true;
      var opener = e.target && e.target.tagName && e.target.tagName.toLowerCase() == 'li' ? e.target : jcf.lib.getParent(e.target, 'li');
      if(opener) {
        this.realElement.selectedIndex = parseInt(opener.getAttribute('rel'));
        this.refreshSelectedClass(parseInt(opener.getAttribute('rel')));
      }
    } else {
      this.keyboardFix = false;
    }
  },
  onDropLeave: function(){
    this.hoverFlag = false;
  },
  isActiveDrop: function(){
    return !jcf.lib.hasClass(this.selectDrop, this.options.dropHiddenClass);
  },
  isOverDrop: function(){
    return this.hoverFlag;
  },
  createDropdown: function(){
    // remove old dropdown if exists
    if(this.selectDrop) {
      this.selectDrop.parentNode.removeChild(this.selectDrop);
    }

    // create dropdown holder
    this.selectDrop = document.createElement('div');
    this.selectDrop.className = this.options.dropClass;
    this.selectDrop.innerHTML = this.options.dropStructure;
    jcf.lib.setStyles(this.selectDrop, {position:'absolute'});
    this.selectList = jcf.lib.queryBySelector(this.options.dropSelector,this.selectDrop)[0];
    jcf.lib.addClass(this.selectDrop, this.options.dropHiddenClass);
    document.body.appendChild(this.selectDrop);
    this.selectDrop.jcf = this;
    jcf.lib.event.add(this.selectDrop, 'click', this.onOptionClick, this);
    jcf.lib.event.add(this.selectDrop, 'mouseover', this.onDropHover, this);
    jcf.lib.event.add(this.selectDrop, 'mouseout', this.onDropLeave, this);
    this.buildDropdown();
  },
  buildDropdown: function() {
    // build select options / optgroups
    this.buildDropdownOptions();

    // position and resize dropdown
    this.positionDropdown();

    // cut dropdown if height exceedes
    this.buildDropdownScroll();
  },
  buildDropdownOptions: function() {
    this.resStructure = '';
    this.optNum = 0;
    for(var i = 0; i < this.realElement.children.length; i++) {
      this.resStructure += this.buildElement(this.realElement.children[i], i) +'\n';
    }
    this.selectList.innerHTML = this.resStructure;
  },
  buildDropdownScroll: function() {
    if(this.options.dropMaxHeight) {
      if(this.selectDrop.offsetHeight > this.options.dropMaxHeight) {
        this.selectList.style.height = this.options.dropMaxHeight+'px';
        this.selectList.style.overflow = 'auto';
        this.selectList.style.overflowX = 'hidden';
        jcf.lib.addClass(this.selectDrop, this.options.dropScrollableClass);
      }
    }
    jcf.lib.addClass(this.selectDrop, jcf.lib.getAllClasses(this.realElement.className, this.options.dropClassPrefix, jcf.baseOptions.hiddenClass));
  },
  parseOptionTitle: function(optTitle) {
    return (typeof optTitle === 'string' && /\.(jpg|gif|png|bmp|jpeg)(.*)?$/i.test(optTitle)) ? optTitle : '';
  },
  buildElement: function(obj, index){
    // build option
    var res = '', optImage;
    if(obj.tagName.toLowerCase() == 'option') {
      if(!jcf.lib.prevSibling(obj) || jcf.lib.prevSibling(obj).tagName.toLowerCase() != 'option') {
        res += '<ul>';
      }
      
      optImage = this.parseOptionTitle(obj.title);
      res += '<li rel="'+(this.optNum++)+'" class="'+(obj.className? obj.className + ' ' : '')+(index % 2 ? 'option-even ' : '')+'jcfcalc"><a href="#">'+(optImage ? '<img src="'+optImage+'" alt="" />' : '')+'<span>' + obj.innerHTML + '</span></a></li>';
      if(!jcf.lib.nextSibling(obj) || jcf.lib.nextSibling(obj).tagName.toLowerCase() != 'option') {
        res += '</ul>';
      }
      return res;
    }
    // build option group with options
    else if(obj.tagName.toLowerCase() == 'optgroup' && obj.label) {
      res += '<div class="'+this.options.optGroupClass+'">';
      res += '<strong class="jcfcalc"><em>'+(obj.label)+'</em></strong>';
      for(var i = 0; i < obj.children.length; i++) {
        res += this.buildElement(obj.children[i], i);
      }
      res += '</div>';
      return res;
    }
  },
  positionDropdown: function(){
    var ofs = jcf.lib.getOffset(this.fakeElement), selectAreaHeight = this.fakeElement.offsetHeight, selectDropHeight = this.selectDrop.offsetHeight;
    var fitInTop = ofs.top - selectDropHeight >= jcf.lib.getScrollTop() && jcf.lib.getScrollTop() + jcf.lib.getWindowHeight() < ofs.top + selectAreaHeight + selectDropHeight;
    
    
    if((this.options.handleDropPosition && fitInTop) || this.options.selectDropPosition === 'top') {
      this.selectDrop.style.top = (ofs.top - selectDropHeight)+'px';
      jcf.lib.addClass(this.selectDrop, this.options.dropFlippedClass);
    } else {
      this.selectDrop.style.top = (ofs.top + selectAreaHeight)+'px';
      jcf.lib.removeClass(this.selectDrop, this.options.dropFlippedClass);
    }
    this.selectDrop.style.left = ofs.left+'px';
    this.selectDrop.style.width = this.fakeElement.offsetWidth+'px';
  },
  showDropdown: function(){
    document.body.appendChild(this.selectDrop);
    jcf.lib.removeClass(this.selectDrop, this.options.dropHiddenClass);
    jcf.lib.addClass(this.fakeElement,this.options.dropActiveClass);
    this.positionDropdown();

    // highlight current active item
    var activeItem = this.getFakeActiveOption();
    this.removeClassFromItems(this.options.currentSelectedClass);
    jcf.lib.addClass(activeItem, this.options.currentSelectedClass);
    
    // show current dropdown
    jcf.lib.event.add(window, 'resize', this.onResizeWindow, this);
    jcf.lib.event.add(window, 'scroll', this.onScrollWindow, this);
    jcf.lib.event.add(document, jcf.eventPress, this.onClickOutside, this);
    this.positionDropdown();
  },
  hideDropdown: function(partial){
    if(this.selectDrop.parentNode) {
      if(this.selectDrop.offsetWidth) {
        this.selectDrop.parentNode.removeChild(this.selectDrop);
      }
      if(partial) {
        return;
      }
    }
    if(typeof this.origSelectedIndex === 'number') {
      this.realElement.selectedIndex = this.origSelectedIndex;
    }
    jcf.lib.removeClass(this.fakeElement,this.options.dropActiveClass);
    jcf.lib.addClass(this.selectDrop, this.options.dropHiddenClass);
    jcf.lib.event.remove(window, 'resize', this.onResizeWindow);
    jcf.lib.event.remove(window, 'scroll', this.onScrollWindow);
    jcf.lib.event.remove(document.documentElement, jcf.eventPress, this.onClickOutside);
    if(jcf.isTouchDevice) {
      this.onBlur();
    }
  },
  toggleDropdown: function(){
    if(!this.realElement.disabled) {
      if(jcf.isTouchDevice) {
        this.onFocus();
      } else {
        this.realElement.focus();
      }
      if(this.isActiveDrop()) {
        this.hideDropdown();
      } else {
        this.showDropdown();
      }
      this.refreshState();
    }
  },
  scrollToItem: function(){
    if(this.isActiveDrop()) {
      var dropHeight = this.selectList.offsetHeight;
      var offsetTop = this.calcOptionOffset(this.getFakeActiveOption());
      var sTop = this.selectList.scrollTop;
      var oHeight = this.getFakeActiveOption().offsetHeight;
      //offsetTop+=sTop;

      if(offsetTop >= sTop + dropHeight) {
        this.selectList.scrollTop = offsetTop - dropHeight + oHeight;
      } else if(offsetTop < sTop) {
        this.selectList.scrollTop = offsetTop;
      }
    }
  },
  getFakeActiveOption: function(c) {
    return jcf.lib.queryBySelector('li[rel="'+(typeof c === 'number' ? c : this.realElement.selectedIndex) +'"]',this.selectList)[0];
  },
  calcOptionOffset: function(fake) {
    var h = 0;
    var els = jcf.lib.queryBySelector('.jcfcalc',this.selectList);
    for(var i = 0; i < els.length; i++) {
      if(els[i] == fake) break;
      h+=els[i].offsetHeight;
    }
    return h;
  },
  childrenHasItem: function(hold,item) {
    var items = hold.getElementsByTagName('*');
    for(i = 0; i < items.length; i++) {
      if(items[i] == item) return true;
    }
    return false;
  },
  removeClassFromItems: function(className){
    var children = jcf.lib.queryBySelector('li',this.selectList);
    for(var i = children.length - 1; i >= 0; i--) {
      jcf.lib.removeClass(children[i], className);
    }
  },
  setSelectedClass: function(c){
    jcf.lib.addClass(this.getFakeActiveOption(c), this.options.selectedClass);
  },
  refreshSelectedClass: function(c){
    if(!this.options.showNativeDrop) {
      this.removeClassFromItems(this.options.selectedClass);
      this.setSelectedClass(c);
    }
    if(this.realElement.disabled) {
      jcf.lib.addClass(this.fakeElement, this.options.disabledClass);
      if(this.labelFor) {
        jcf.lib.addClass(this.labelFor, this.options.labelDisabledClass);
      }
    } else {
      jcf.lib.removeClass(this.fakeElement, this.options.disabledClass);
      if(this.labelFor) {
        jcf.lib.removeClass(this.labelFor, this.options.labelDisabledClass);
      }
    }
  },
  refreshSelectedText: function() {
    if(!this.dropOpened && this.realElement.title) {
      this.valueText.innerHTML = this.realElement.title;
    } else {
      if(this.realElement.options[this.realElement.selectedIndex].title) {
        var optImage = this.parseOptionTitle(this.realElement.options[this.realElement.selectedIndex].title);
        this.valueText.innerHTML = (optImage ? '<img src="'+optImage+'" alt="" />' : '') + this.realElement.options[this.realElement.selectedIndex].innerHTML;
      } else {
        this.valueText.innerHTML = this.realElement.options[this.realElement.selectedIndex].innerHTML;
      }
    }
  },
  refreshState: function(){
    this.origSelectedIndex = this.realElement.selectedIndex;
    this.refreshSelectedClass();
    this.refreshSelectedText();
    if(!this.options.showNativeDrop) {
      this.positionDropdown();
      if(this.selectDrop.offsetWidth) {
        this.scrollToItem();
      }
    }
  }
});
*/

/*
// custom checkbox module
jcf.addModule({
  name:'checkbox',
  selector:'input[type="checkbox"]',
  defaultOptions: {
    wrapperClass:'chk-area',
    focusClass:'chk-focus',
    checkedClass:'chk-checked',
    labelActiveClass:'chk-label-active',
    uncheckedClass:'chk-unchecked',
    disabledClass:'chk-disabled',
    chkStructure:'<span></span>'
  },
  setupWrapper: function(){
    jcf.lib.addClass(this.fakeElement, this.options.wrapperClass);
    this.fakeElement.innerHTML = this.options.chkStructure;
    this.realElement.parentNode.insertBefore(this.fakeElement, this.realElement);
    jcf.lib.event.add(this.realElement, 'click', this.onRealClick, this);
    this.refreshState();
  },
  isLinkTarget: function(target, limitParent) {
    while(target.parentNode || target === limitParent) {
      if(target.tagName.toLowerCase() === 'a') {
        return true;
      }
      target = target.parentNode;
    }
  },
  onFakePressed: function() {
    jcf.modules[this.name].superclass.onFakePressed.apply(this, arguments);
    if(!this.realElement.disabled) {
      this.realElement.focus();
    }
  },
  onFakeClick: function(e) {
    jcf.modules[this.name].superclass.onFakeClick.apply(this, arguments);
    this.tmpTimer = setTimeout(jcf.lib.bind(function(){
      this.toggle();
    },this),10);
    if(!this.isLinkTarget(e.target, this.labelFor)) {
      return false;
    }
  },
  onRealClick: function(e) {
    setTimeout(jcf.lib.bind(function(){
      this.refreshState();
    },this),10);
    e.stopPropagation();
  },
  toggle: function(e){
    if(!this.realElement.disabled) {
      if(this.realElement.checked) {
        this.realElement.checked = false;
      } else {
        this.realElement.checked = true;
      }
    }
    this.refreshState();
    return false;
  },
  refreshState: function(){
    if(this.realElement.checked) {
      jcf.lib.addClass(this.fakeElement, this.options.checkedClass);
      jcf.lib.removeClass(this.fakeElement, this.options.uncheckedClass);
      if(this.labelFor) {
        jcf.lib.addClass(this.labelFor, this.options.labelActiveClass);
      }
    } else {
      jcf.lib.removeClass(this.fakeElement, this.options.checkedClass);
      jcf.lib.addClass(this.fakeElement, this.options.uncheckedClass);
      if(this.labelFor) {
        jcf.lib.removeClass(this.labelFor, this.options.labelActiveClass);
      }
    }
    if(this.realElement.disabled) {
      jcf.lib.addClass(this.fakeElement, this.options.disabledClass);
      if(this.labelFor) {
        jcf.lib.addClass(this.labelFor, this.options.labelDisabledClass);
      }
    } else {
      jcf.lib.removeClass(this.fakeElement, this.options.disabledClass);
      if(this.labelFor) {
        jcf.lib.removeClass(this.labelFor, this.options.labelDisabledClass);
      }
    }
  }
});
*/

// custom scrollbars module
jcf.addModule({
  name:'customscroll',
  selector:'div.scrollable-area',
  defaultOptions: {
    alwaysPreventWheel: false,
    enableMouseWheel: true,
    captureFocus: false,
    handleNested: true,
    alwaysKeepScrollbars: false,
    autoDetectWidth: false,
    scrollbarOptions: {},
    focusClass:'scrollable-focus',
    wrapperTag: 'div',
    autoDetectWidthClass: 'autodetect-width',
    noHorizontalBarClass:'noscroll-horizontal',
    noVerticalBarClass:'noscroll-vertical',
    innerWrapperClass:'scrollable-inner-wrapper',
    outerWrapperClass:'scrollable-area-wrapper',
    horizontalClass: 'hscrollable',
    verticalClass: 'vscrollable',
    bothClass: 'anyscrollable'
  },
  replaceObject: function(){
    this.initStructure();
    this.refreshState();
    this.addEvents();
  },
  initStructure: function(){
    // set scroll type
    this.realElement.jcf = this;
    if(jcf.lib.hasClass(this.realElement, this.options.bothClass) || 
    jcf.lib.hasClass(this.realElement, this.options.horizontalClass) && jcf.lib.hasClass(this.realElement, this.options.verticalClass)) {
      this.scrollType = 'both';
    } else if(jcf.lib.hasClass(this.realElement, this.options.horizontalClass)) {
      this.scrollType = 'horizontal';
    } else {
      this.scrollType = 'vertical';
    }
    
    // autodetect horizontal width
    if(jcf.lib.hasClass(this.realElement,this.options.autoDetectWidthClass)) {
      this.options.autoDetectWidth = true;
    }
    
    // init dimensions and build structure
    this.realElement.style.position = 'relative';
    this.realElement.style.overflow = 'hidden';
    
    // build content wrapper and scrollbar(s)
    this.buildWrapper();
    this.buildScrollbars();
  },
  buildWrapper: function() {
    this.outerWrapper = document.createElement(this.options.wrapperTag);
    this.outerWrapper.className = this.options.outerWrapperClass;
    this.realElement.parentNode.insertBefore(this.outerWrapper, this.realElement);
    this.outerWrapper.appendChild(this.realElement);
    
    // autosize content if single child
    if(this.options.autoDetectWidth && (this.scrollType === 'both' || this.scrollType === 'horizontal') && this.realElement.children.length === 1) {
      var tmpWidth = 0;
      this.realElement.style.width = '99999px';
      tmpWidth = this.realElement.children[0].offsetWidth;
      this.realElement.style.width = '';
      if(tmpWidth) {
        this.realElement.children[0].style.width = tmpWidth+'px';
      }
    }
  },
  buildScrollbars: function() {
    if(this.scrollType === 'horizontal' || this.scrollType === 'both') {
      this.hScrollBar = new jcf.plugins.scrollbar(jcf.lib.extend(this.options.scrollbarOptions,{
        vertical: false,
        spawnClass: this,
        holder: this.outerWrapper,
        range: this.realElement.scrollWidth - this.realElement.offsetWidth,
        size: this.realElement.offsetWidth,
        onScroll: jcf.lib.bind(function(v) {
          this.realElement.scrollLeft = v;
        },this)
      }));
    }
    if(this.scrollType === 'vertical' || this.scrollType === 'both') {
      this.vScrollBar = new jcf.plugins.scrollbar(jcf.lib.extend(this.options.scrollbarOptions,{
        vertical: true,
        spawnClass: this,
        holder: this.outerWrapper,
        range: this.realElement.scrollHeight - this.realElement.offsetHeight,
        size: this.realElement.offsetHeight,
        onScroll: jcf.lib.bind(function(v) {
          this.realElement.scrollTop = v;
        },this)
      }));
    }
    this.outerWrapper.style.width = this.realElement.offsetWidth + 'px';
    this.outerWrapper.style.height = this.realElement.offsetHeight + 'px';
    this.resizeScrollContent();
  },
  resizeScrollContent: function() {
    var diffWidth = this.realElement.offsetWidth - jcf.lib.getInnerWidth(this.realElement);
    var diffHeight = this.realElement.offsetHeight - jcf.lib.getInnerHeight(this.realElement);
    this.realElement.style.width = Math.max(0, this.outerWrapper.offsetWidth - diffWidth - (this.vScrollBar ? this.vScrollBar.getScrollBarSize() : 0)) + 'px';
    this.realElement.style.height = Math.max(0, this.outerWrapper.offsetHeight - diffHeight - (this.hScrollBar ? this.hScrollBar.getScrollBarSize() : 0)) + 'px';
  },
  addEvents: function() {
    // enable mouse wheel handling
    if(!jcf.isTouchDevice && this.options.enableMouseWheel) {
      jcf.lib.event.add(this.outerWrapper, 'mousewheel', this.onMouseWheel, this);
    }
    // add touch scroll on block body
    if(jcf.isTouchDevice || navigator.msPointerEnabled) {
      this.outerWrapper.style.msTouchAction = 'none';
      jcf.lib.event.add(this.realElement, jcf.eventPress, this.onScrollablePress, this);
    }
    
    // handle nested scrollbars
    if(this.options.handleNested) {
      var el = this.realElement, name = this.name;
      while(el.parentNode) {
        if(el.parentNode.jcf && el.parentNode.jcf.name == name) {
          el.parentNode.jcf.refreshState();
        }
        el = el.parentNode;
      }
    }
  },
  onMouseWheel: function(e) {
    if(this.scrollType === 'vertical' || this.scrollType === 'both') {
      return this.vScrollBar.doScrollWheelStep(e.mWheelDelta) === false ? false : !this.options.alwaysPreventWheel;
    } else {
      return this.hScrollBar.doScrollWheelStep(e.mWheelDelta) === false ? false : !this.options.alwaysPreventWheel;
    }
  },
  onScrollablePress: function(e) {
    if(e.pointerType !== e.MSPOINTER_TYPE_TOUCH) return;

    this.preventFlag = true;
    this.origWindowScrollTop = jcf.lib.getScrollTop();
    this.origWindowScrollLeft = jcf.lib.getScrollLeft();
  
    this.scrollableOffset = jcf.lib.getOffset(this.realElement);
    if(this.hScrollBar) {
      this.scrollableTouchX = (jcf.isTouchDevice ? e.changedTouches[0] : e).pageX;
      this.origValueX = this.hScrollBar.getScrollValue();
    }
    if(this.vScrollBar) {
      this.scrollableTouchY = (jcf.isTouchDevice ? e.changedTouches[0] : e).pageY;
      this.origValueY = this.vScrollBar.getScrollValue();
    }
    jcf.lib.event.add(this.realElement, jcf.eventMove, this.onScrollableMove, this);
    jcf.lib.event.add(this.realElement, jcf.eventRelease, this.onScrollableRelease, this);
  },
  onScrollableMove: function(e) {
    if(this.vScrollBar) {
      var difY = (jcf.isTouchDevice ? e.changedTouches[0] : e).pageY - this.scrollableTouchY;
      var valY = this.origValueY-difY;
      this.vScrollBar.scrollTo(valY);
      if(valY < 0 || valY > this.vScrollBar.options.range) {
        this.preventFlag = false;
      }
    }
    if(this.hScrollBar) {
      var difX = (jcf.isTouchDevice ? e.changedTouches[0] : e).pageX - this.scrollableTouchX;
      var valX = this.origValueX-difX;
      this.hScrollBar.scrollTo(valX);
      if(valX < 0 || valX > this.hScrollBar.options.range) {
        this.preventFlag = false;
      }
    }
    if(this.preventFlag) {
      e.preventDefault();
    }
  },
  onScrollableRelease: function() {
    jcf.lib.event.remove(this.realElement, jcf.eventMove, this.onScrollableMove);
    jcf.lib.event.remove(this.realElement, jcf.eventRelease, this.onScrollableRelease);
  },
  refreshState: function() {
    if(this.options.alwaysKeepScrollbars) {
      if(this.hScrollBar) this.hScrollBar.scrollBar.style.display = 'block';
      if(this.vScrollBar) this.vScrollBar.scrollBar.style.display = 'block';
    } else {
      if(this.hScrollBar) {
        if(this.getScrollRange(false)) {
          this.hScrollBar.scrollBar.style.display = 'block';
          this.resizeScrollContent();
          this.hScrollBar.setRange(this.getScrollRange(false));
        } else {
          this.hScrollBar.scrollBar.style.display = 'none';
          this.realElement.style.width = this.outerWrapper.style.width;
        }
        jcf.lib.toggleClass(this.outerWrapper, this.options.noHorizontalBarClass, this.hScrollBar.options.range === 0);
      }
      if(this.vScrollBar) {
        if(this.getScrollRange(true) > 0) {
          this.vScrollBar.scrollBar.style.display = 'block';
          this.resizeScrollContent();
          this.vScrollBar.setRange(this.getScrollRange(true));
        } else {
          this.vScrollBar.scrollBar.style.display = 'none';
          this.realElement.style.width = this.outerWrapper.style.width;
        }
        jcf.lib.toggleClass(this.outerWrapper, this.options.noVerticalBarClass, this.vScrollBar.options.range === 0);
      }
    }
    if(this.vScrollBar) {
      this.vScrollBar.setRange(this.realElement.scrollHeight - this.realElement.offsetHeight);
      this.vScrollBar.setSize(this.realElement.offsetHeight);
      this.vScrollBar.scrollTo(this.realElement.scrollTop);
    }
    if(this.hScrollBar) {
      this.hScrollBar.setRange(this.realElement.scrollWidth - this.realElement.offsetWidth);
      this.hScrollBar.setSize(this.realElement.offsetWidth);
      this.hScrollBar.scrollTo(this.realElement.scrollLeft);
    }
  },
  getScrollRange: function(isVertical) {
    if(isVertical) {
      return this.realElement.scrollHeight - this.realElement.offsetHeight;
    } else {
      return this.realElement.scrollWidth - this.realElement.offsetWidth;
    }
  },
  getCurrentRange: function(scrollInstance) {
    return this.getScrollRange(scrollInstance.isVertical);
  },
  onCreateModule: function(){
    if(jcf.modules.select) {
      this.extendSelect();
    }
    if(jcf.modules.selectmultiple) {
      this.extendSelectMultiple();
    }
    if(jcf.modules.textarea) {
      this.extendTextarea();
    }
  },
  onModuleAdded: function(module){
    if(module.prototype.name == 'select') {
      this.extendSelect();
    }
    if(module.prototype.name == 'selectmultiple') {
      this.extendSelectMultiple();
    }
    if(module.prototype.name == 'textarea') {
      this.extendTextarea();
    }
  },
  extendSelect: function() {
    // add scrollable if needed on control ready
    jcf.modules.select.prototype.onControlReady = function(obj){
      if(obj.selectList.scrollHeight > obj.selectList.offsetHeight) {
        obj.jcfScrollable = new jcf.modules.customscroll({
          alwaysPreventWheel: true,
          replaces:obj.selectList
        });
      }
    }
    // update scroll function
    var orig = jcf.modules.select.prototype.scrollToItem;
    jcf.modules.select.prototype.scrollToItem = function(){
      orig.apply(this);
      if(this.jcfScrollable) {
        this.jcfScrollable.refreshState();
      }
    }
  },
  extendTextarea: function() {
    // add scrollable if needed on control ready
    jcf.modules.textarea.prototype.onControlReady = function(obj){
      obj.jcfScrollable = new jcf.modules.customscroll({
        alwaysKeepScrollbars: true,
        alwaysPreventWheel: true,
        replaces: obj.realElement
      });
    }
    // update scroll function
    var orig = jcf.modules.textarea.prototype.refreshState;
    jcf.modules.textarea.prototype.refreshState = function(){
      orig.apply(this);
      if(this.jcfScrollable) {
        this.jcfScrollable.refreshState();
      }
    }
  },
  extendSelectMultiple: function(){
    // add scrollable if needed on control ready
    jcf.modules.selectmultiple.prototype.onControlReady = function(obj){
      //if(obj.optionsHolder.scrollHeight > obj.optionsHolder.offsetHeight) {
        obj.jcfScrollable = new jcf.modules.customscroll({
          alwaysPreventWheel: true,
          replaces:obj.optionsHolder
        });
      //}
    }
    // update scroll function
    var orig = jcf.modules.selectmultiple.prototype.scrollToItem;
    jcf.modules.selectmultiple.prototype.scrollToItem = function(){
      orig.apply(this);
      if(this.jcfScrollable) {
        this.jcfScrollable.refreshState();
      }
    }
    
    // update scroll size?
    var orig2 = jcf.modules.selectmultiple.prototype.rebuildOptions;
    jcf.modules.selectmultiple.prototype.rebuildOptions = function(){
      orig2.apply(this);
      if(this.jcfScrollable) {
        this.jcfScrollable.refreshState();
      }
    }
    
  }
});

// scrollbar plugin
jcf.addPlugin({
  name: 'scrollbar',
  defaultOptions: {
    size: 0,
    range: 0,
    moveStep: 6,
    moveDistance: 50,
    moveInterval: 10,
    trackHoldDelay: 900,
    holder: null,
    vertical: true,
    scrollTag: 'div',
    onScroll: function(){},
    onScrollEnd: function(){},
    onScrollStart: function(){},
    disabledClass: 'btn-disabled',
    VscrollBarClass:'vscrollbar',
    VscrollStructure: '<div class="vscroll-up"></div><div class="vscroll-line"><div class="vscroll-slider"><div class="scroll-bar-top"></div><div class="scroll-bar-bottom"></div></div></div></div><div class="vscroll-down"></div>',
    VscrollTrack: 'div.vscroll-line',
    VscrollBtnDecClass:'div.vscroll-up',
    VscrollBtnIncClass:'div.vscroll-down',
    VscrollSliderClass:'div.vscroll-slider',
    HscrollBarClass:'hscrollbar',
    HscrollStructure: '<div class="hscroll-left"></div><div class="hscroll-line"><div class="hscroll-slider"><div class="scroll-bar-left"></div><div class="scroll-bar-right"></div></div></div></div><div class="hscroll-right"></div>',
    HscrollTrack: 'div.hscroll-line',
    HscrollBtnDecClass:'div.hscroll-left',
    HscrollBtnIncClass:'div.hscroll-right',
    HscrollSliderClass:'div.hscroll-slider'
  },
  init: function(userOptions) {
    this.setOptions(userOptions);
    this.createScrollBar();
    this.attachEvents();
    this.setSize();
  },
  setOptions: function(extOptions) {
    // merge options
    this.options = jcf.lib.extend({}, this.defaultOptions, extOptions);
    this.isVertical = this.options.vertical;
    this.prefix = this.isVertical ? 'V' : 'H';
    this.eventPageOffsetProperty = this.isVertical ? 'pageY' : 'pageX';
    this.positionProperty = this.isVertical ? 'top' : 'left';
    this.sizeProperty = this.isVertical ? 'height' : 'width';
    this.dimenionsProperty = this.isVertical ? 'offsetHeight' : 'offsetWidth';
    this.invertedDimenionsProperty = !this.isVertical ? 'offsetHeight' : 'offsetWidth';
    
    // set corresponding classes
    for(var p in this.options) {
      if(p.indexOf(this.prefix) == 0) {
        this.options[p.substr(1)] = this.options[p];
      }
    }
  },
  createScrollBar: function() {
    // create dimensions
    this.scrollBar = document.createElement(this.options.scrollTag);
    this.scrollBar.className = this.options.scrollBarClass;
    this.scrollBar.innerHTML = this.options.scrollStructure;
    
    // get elements
    this.track = jcf.lib.queryBySelector(this.options.scrollTrack,this.scrollBar)[0];
    this.btnDec = jcf.lib.queryBySelector(this.options.scrollBtnDecClass,this.scrollBar)[0];
    this.btnInc = jcf.lib.queryBySelector(this.options.scrollBtnIncClass,this.scrollBar)[0];
    this.slider = jcf.lib.queryBySelector(this.options.scrollSliderClass,this.scrollBar)[0];
    this.slider.style.position = 'absolute';
    this.track.style.position = 'relative';
  },
  attachEvents: function() {
    // append scrollbar to holder if provided
    if(this.options.holder) {
      this.options.holder.appendChild(this.scrollBar);
    }
    
    // attach listeners for slider and buttons
    jcf.lib.event.add(this.slider, jcf.eventPress, this.onSliderPressed, this);
    jcf.lib.event.add(this.btnDec, jcf.eventPress, this.onBtnDecPressed, this);
    jcf.lib.event.add(this.btnInc, jcf.eventPress, this.onBtnIncPressed, this);
    jcf.lib.event.add(this.track, jcf.eventPress, this.onTrackPressed, this);
  },
  setSize: function(value) {
    if(typeof value === 'number') {
      this.options.size = value;
    }
    this.scrollOffset = this.scrollValue = this.sliderOffset = 0;
    this.scrollBar.style[this.sizeProperty] = this.options.size + 'px';
    this.resizeControls();
    this.refreshSlider();
  },
  setRange: function(r) {
    this.options.range = Math.max(r,0);
    this.resizeControls();
  },
  doScrollWheelStep: function(direction) {
    // 1 - scroll up, -1 scroll down
    this.startScroll();
    if((direction < 0 && !this.isEndPosition()) || (direction > 0 && !this.isStartPosition())) {
      this.scrollTo(this.getScrollValue()-this.options.moveDistance * direction);
      this.moveScroll();
      this.endScroll();
      return false;
    }
  },
  resizeControls: function() {
    // calculate dimensions
    this.barSize = this.scrollBar[this.dimenionsProperty];
    this.btnDecSize = this.btnDec[this.dimenionsProperty];
    this.btnIncSize = this.btnInc[this.dimenionsProperty];
    this.trackSize = this.barSize - this.btnDecSize - this.btnIncSize;
    
    // resize and reposition elements
    this.track.style[this.sizeProperty] = this.trackSize + 'px';
    this.trackSize = this.track[this.dimenionsProperty];
    this.sliderSize = this.getSliderSize();
    this.slider.style[this.sizeProperty] = this.sliderSize + 'px';
    this.sliderSize = this.slider[this.dimenionsProperty];
  },
  refreshSlider: function(complete) {
    // refresh dimensions
    if(complete) {
      this.resizeControls();
    }
    // redraw slider and classes
    this.sliderOffset = isNaN(this.sliderOffset) ? 0 : this.sliderOffset;
    this.slider.style[this.positionProperty] = this.sliderOffset + 'px';
  },
  startScroll: function() {
    // refresh range if possible
    if(this.options.spawnClass && typeof this.options.spawnClass.getCurrentRange === 'function') {
      this.setRange(this.options.spawnClass.getCurrentRange(this));
    }
    this.resizeControls();
    this.scrollBarOffset = jcf.lib.getOffset(this.track)[this.positionProperty];
    this.options.onScrollStart();
  },
  moveScroll: function() {
    this.options.onScroll(this.scrollValue);
    
    // add disabled classes
    jcf.lib.removeClass(this.btnDec, this.options.disabledClass);
    jcf.lib.removeClass(this.btnInc, this.options.disabledClass);
    if(this.scrollValue === 0) {
      jcf.lib.addClass(this.btnDec, this.options.disabledClass);
    }
    if(this.scrollValue === this.options.range) {
      jcf.lib.addClass(this.btnInc, this.options.disabledClass);
    }
  },
  endScroll: function() {
    this.options.onScrollEnd();
  },
  startButtonMoveScroll: function(direction) {
    this.startScroll();
    clearInterval(this.buttonScrollTimer);
    this.buttonScrollTimer = setInterval(jcf.lib.bind(function(){
      this.scrollValue += this.options.moveStep * direction
      if(this.scrollValue > this.options.range) {
        this.scrollValue = this.options.range;
        this.endButtonMoveScroll();
      } else if(this.scrollValue < 0) {
        this.scrollValue = 0;
        this.endButtonMoveScroll();
      }
      this.scrollTo(this.scrollValue);
      
    },this),this.options.moveInterval);
  },
  endButtonMoveScroll: function() {
    clearInterval(this.buttonScrollTimer);
    this.endScroll();
  },
  isStartPosition: function() {
    return this.scrollValue === 0;
  },
  isEndPosition: function() {
    return this.scrollValue === this.options.range;
  },
  getSliderSize: function() {
    return Math.round(this.getSliderSizePercent() * this.trackSize / 100);
  },
  getSliderSizePercent: function() {
    return this.options.range === 0 ? 0 : this.barSize * 100 / (this.barSize + this.options.range);
  },
  getSliderOffsetByScrollValue: function() {
    return (this.scrollValue * 100 / this.options.range) * (this.trackSize - this.sliderSize) / 100;
  },
  getSliderOffsetPercent: function() {
    return this.sliderOffset * 100 / (this.trackSize - this.sliderSize);
  },
  getScrollValueBySliderOffset: function() {
    return this.getSliderOffsetPercent() * this.options.range / 100;
  },
  getScrollBarSize: function() {
    return this.scrollBar[this.invertedDimenionsProperty];
  },
  getScrollValue: function() {
    return this.scrollValue || 0;
  },
  scrollOnePage: function(direction) {
    this.scrollTo(this.scrollValue + direction*this.barSize);
  },
  scrollTo: function(x) {
    this.scrollValue = x < 0 ? 0 : x > this.options.range ? this.options.range : x;
    this.sliderOffset = this.getSliderOffsetByScrollValue();
    this.refreshSlider();
    this.moveScroll();
  },
  onSliderPressed: function(e){
    jcf.lib.event.add(document.body, jcf.eventRelease, this.onSliderRelease, this);
    jcf.lib.event.add(document.body, jcf.eventMove, this.onSliderMove, this);
    jcf.lib.disableTextSelection(this.slider);
    
    // calculate offsets once
    this.sliderInnerOffset = (jcf.isTouchDevice ? e.changedTouches[0] : e)[this.eventPageOffsetProperty] - jcf.lib.getOffset(this.slider)[this.positionProperty];
    this.startScroll();
    return false;
  },
  onSliderRelease: function(){
    jcf.lib.event.remove(document.body, jcf.eventRelease, this.onSliderRelease);
    jcf.lib.event.remove(document.body, jcf.eventMove, this.onSliderMove);
  },
  onSliderMove: function(e) {
    this.sliderOffset = (jcf.isTouchDevice ? e.changedTouches[0] : e)[this.eventPageOffsetProperty] - this.scrollBarOffset - this.sliderInnerOffset;
    if(this.sliderOffset < 0) {
      this.sliderOffset = 0;
    } else if(this.sliderOffset + this.sliderSize > this.trackSize) {
      this.sliderOffset = this.trackSize - this.sliderSize;
    }
    if(this.previousOffset != this.sliderOffset) {
      this.previousOffset = this.sliderOffset;
      this.scrollTo(this.getScrollValueBySliderOffset());
    }
  },
  onBtnIncPressed: function() {
    jcf.lib.event.add(document.body, jcf.eventRelease, this.onBtnIncRelease, this);
    jcf.lib.disableTextSelection(this.btnInc);
    this.startButtonMoveScroll(1);
    return false;
  },
  onBtnIncRelease: function() {
    jcf.lib.event.remove(document.body, jcf.eventRelease, this.onBtnIncRelease);
    this.endButtonMoveScroll();
  },
  onBtnDecPressed: function() {
    jcf.lib.event.add(document.body, jcf.eventRelease, this.onBtnDecRelease, this);
    jcf.lib.disableTextSelection(this.btnDec);
    this.startButtonMoveScroll(-1);
    return false;
  },
  onBtnDecRelease: function() {
    jcf.lib.event.remove(document.body, jcf.eventRelease, this.onBtnDecRelease);
    this.endButtonMoveScroll();
  },
  onTrackPressed: function(e) {
    var position = e[this.eventPageOffsetProperty] - jcf.lib.getOffset(this.track)[this.positionProperty];
    var direction = position < this.sliderOffset ? -1 : position > this.sliderOffset + this.sliderSize ? 1 : 0;
    if(direction) {
      this.scrollOnePage(direction);
    }
  }
});
