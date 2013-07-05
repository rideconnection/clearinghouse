// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require jquery-ui-1.10.0
//= require jquery-ui-timepicker-addon
//= require jquery.placeholder.min
//= require jcf
//= require_tree .

// page init
jQuery(function(){
  jcf.customForms.replaceAll();
  initOpenClose();
  // initInputs();
  // initDatePicker();
  // jQuery Placeholder plugin, adds placeholder support for browsers that don't support it natively
  $('input, textarea').placeholder();
});

// open-close init
function initOpenClose() {
  jQuery('.details-box').openClose({
    activeClass: 'active',
    opener: '.opener',
    slider: '.slide',
    animSpeed: 400,
    effect: 'slide'
  });
  jQuery('.form-holder').openClose({
    activeClass: 'active',
    opener: '.opener',
    slider: '.slide',
    animSpeed: 400,
    effect: 'slide'
  });
  jQuery('.saved-filter-form').openClose({
    activeClass: 'active',
    opener: '.opener',
    slider: '.slide',
    animSpeed: 400,
    effect: 'slide'
  });
}

// // clear inputs on focus
// function initInputs() {
//  PlaceholderInput.replaceByOptions({
//    // filter options
//    clearInputs: true,
//    clearTextareas: true,
//    clearPasswords: true,
//    skipClass: 'default',
//    
//    // input options
//    wrapWithElement: false,
//    showUntilTyping: false,
//    getParentByClass: false,
//    placeholderAttr: 'value'
//  });
// }
// 
// //init datepicker 
// function initDatePicker() {
//  jQuery('.reports-list li').each(function() {
//    var row = jQuery(this),
//      from = row.find('.from'),
//      to = row.find('.to');
//    
//     from.datepicker({
//      changeMonth: false,
//      showOn: "both",
//      numberOfMonths: 1,
//      onClose: function( selectedDate ) {
//        to.datepicker( "option", "minDate", selectedDate );
//      }
//    });
//    to.datepicker({
//      changeMonth: false,
//      showOn: "both",
//      numberOfMonths: 1,
//      onClose: function( selectedDate ) {
//        from.datepicker( "option", "maxDate", selectedDate );
//      }
//    });
//  });
// }

/*
 * jQuery Open/Close plugin
 */
(function($) {
  function OpenClose(options) {
    this.options = $.extend({
      addClassBeforeAnimation: true,
      activeClass:'active',
      opener:'.opener',
      slider:'.slide',
      animSpeed: 400,
      effect:'fade',
      event:'click'
    }, options);
    this.init();
  }
  OpenClose.prototype = {
    init: function() {
      if(this.options.holder) {
        this.findElements();
        this.attachEvents();
        this.makeCallback('onInit');
      }
    },
    findElements: function() {
      this.holder = $(this.options.holder);
      this.opener = this.holder.find(this.options.opener);
      this.slider = this.holder.find(this.options.slider);
      
      if (!this.holder.hasClass(this.options.activeClass)) {
        this.slider.addClass(slideHiddenClass);
      }
    },
    attachEvents: function() {
      // add handler
      var self = this;
      this.eventHandler = function(e) {
        e.preventDefault();
        if (self.slider.hasClass(slideHiddenClass)) {
          self.showSlide();
        } else {
          self.hideSlide();
        }
      };
      self.opener.bind(self.options.event, this.eventHandler);

      // hove mode handler
      if(self.options.event === 'over') {
        self.opener.bind('mouseenter', function() {
          self.holder.removeClass(self.options.activeClass);
          self.opener.trigger(self.options.event);
        });
        self.holder.bind('mouseleave', function() {
          self.holder.addClass(self.options.activeClass);
          self.opener.trigger(self.options.event);
        });
      }
    },
    showSlide: function() {
      var self = this;
      if (self.options.addClassBeforeAnimation) {
        self.holder.addClass(self.options.activeClass);
      }
      self.slider.removeClass(slideHiddenClass);

      self.makeCallback('animStart', true);
      toggleEffects[self.options.effect].show({
        box: self.slider,
        speed: self.options.animSpeed,
        complete: function() {
          if (!self.options.addClassBeforeAnimation) {
            self.holder.addClass(self.options.activeClass);
          }
          self.makeCallback('animEnd', true);
        }
      });
    },
    hideSlide: function() {
      var self = this;
      if (self.options.addClassBeforeAnimation) {
        self.holder.removeClass(self.options.activeClass);
      }
      
      self.makeCallback('animStart', false);
      toggleEffects[self.options.effect].hide({
        box: self.slider,
        speed: self.options.animSpeed,
        complete: function() {
          if (!self.options.addClassBeforeAnimation) {
            self.holder.removeClass(self.options.activeClass);
          }
          self.slider.addClass(slideHiddenClass);
          self.makeCallback('animEnd', false);
        }
      });
    },
    destroy: function() {
      this.slider.removeClass(slideHiddenClass);
      this.opener.unbind(this.options.event, this.eventHandler);
      this.holder.removeClass(this.options.activeClass).removeData('OpenClose');
    },
    makeCallback: function(name) {
      if(typeof this.options[name] === 'function') {
        var args = Array.prototype.slice.call(arguments);
        args.shift();
        this.options[name].apply(this, args);
      }
    }
  };
  
  // add stylesheet for slide on DOMReady
  var slideHiddenClass = 'js-slide-hidden';
  $(function() {
    var tabStyleSheet = $('<style type="text/css">')[0];
    var tabStyleRule = '.' + slideHiddenClass;
    tabStyleRule += '{position:absolute !important;left:-9999px !important;top:-9999px !important;display:block !important}';
    if (tabStyleSheet.styleSheet) {
      tabStyleSheet.styleSheet.cssText = tabStyleRule;
    } else {
      tabStyleSheet.appendChild(document.createTextNode(tabStyleRule));
    }
    $('head').append(tabStyleSheet);
  });
  
  // animation effects
  var toggleEffects = {
    slide: {
      show: function(o) {
        o.box.stop(true).hide().slideDown(o.speed, o.complete);
      },
      hide: function(o) {
        o.box.stop(true).slideUp(o.speed, o.complete);
      }
    },
    fade: {
      show: function(o) {
        o.box.stop(true).hide().fadeIn(o.speed, o.complete);
      },
      hide: function(o) {
        o.box.stop(true).fadeOut(o.speed, o.complete);
      }
    },
    none: {
      show: function(o) {
        o.box.hide().show(0, o.complete);
      },
      hide: function(o) {
        o.box.hide(0, o.complete);
      }
    }
  };
  
  // jQuery plugin interface
  $.fn.openClose = function(opt) {
    return this.each(function() {
      jQuery(this).data('OpenClose', new OpenClose($.extend(opt, {holder: this})));
    });
  };
}(jQuery));

// // placeholder class
// (function(){
//  var placeholderCollection = [];
//  PlaceholderInput = function() {
//    this.options = {
//      element:null,
//      showUntilTyping:false,
//      wrapWithElement:false,
//      getParentByClass:false,
//      showPasswordBullets:false,
//      placeholderAttr:'value',
//      inputFocusClass:'focus',
//      inputActiveClass:'text-active',
//      parentFocusClass:'parent-focus',
//      parentActiveClass:'parent-active',
//      labelFocusClass:'label-focus',
//      labelActiveClass:'label-active',
//      fakeElementClass:'input-placeholder-text'
//    };
//    placeholderCollection.push(this);
//    this.init.apply(this,arguments);
//  };
//  PlaceholderInput.refreshAllInputs = function(except) {
//    for(var i = 0; i < placeholderCollection.length; i++) {
//      if(except !== placeholderCollection[i]) {
//        placeholderCollection[i].refreshState();
//      }
//    }
//  };
//  PlaceholderInput.replaceByOptions = function(opt) {
//    var inputs = [].concat(
//      convertToArray(document.getElementsByTagName('input')),
//      convertToArray(document.getElementsByTagName('textarea'))
//    );
//    for(var i = 0; i < inputs.length; i++) {
//      if(inputs[i].className.indexOf(opt.skipClass) < 0) {
//        var inputType = getInputType(inputs[i]);
//        var placeholderValue = inputs[i].getAttribute('placeholder');
//        if(opt.focusOnly || (opt.clearInputs && (inputType === 'text' || inputType === 'email' || placeholderValue)) ||
//          (opt.clearTextareas && inputType === 'textarea') ||
//          (opt.clearPasswords && inputType === 'password')
//        ) {
//          new PlaceholderInput({
//            element:inputs[i],
//            focusOnly: opt.focusOnly,
//            wrapWithElement:opt.wrapWithElement,
//            showUntilTyping:opt.showUntilTyping,
//            getParentByClass:opt.getParentByClass,
//            showPasswordBullets:opt.showPasswordBullets,
//            placeholderAttr: placeholderValue ? 'placeholder' : opt.placeholderAttr
//          });
//        }
//      }
//    }
//  };
//  PlaceholderInput.prototype = {
//    init: function(opt) {
//      this.setOptions(opt);
//      if(this.element && this.element.PlaceholderInst) {
//        this.element.PlaceholderInst.refreshClasses();
//      } else {
//        this.element.PlaceholderInst = this;
//        if(this.elementType !== 'radio' || this.elementType !== 'checkbox' || this.elementType !== 'file') {
//          this.initElements();
//          this.attachEvents();
//          this.refreshClasses();
//        }
//      }
//    },
//    setOptions: function(opt) {
//      for(var p in opt) {
//        if(opt.hasOwnProperty(p)) {
//          this.options[p] = opt[p];
//        }
//      }
//      if(this.options.element) {
//        this.element = this.options.element;
//        this.elementType = getInputType(this.element);
//        if(this.options.focusOnly) {
//          this.wrapWithElement = false;
//        } else {
//          if(this.elementType === 'password' && this.options.showPasswordBullets) {
//            this.wrapWithElement = false;
//          } else {
//            this.wrapWithElement = this.elementType === 'password' || this.options.showUntilTyping ? true : this.options.wrapWithElement;
//          }
//        }
//        this.setPlaceholderValue(this.options.placeholderAttr);
//      }
//    },
//    setPlaceholderValue: function(attr) {
//      this.origValue = (attr === 'value' ? this.element.defaultValue : (this.element.getAttribute(attr) || ''));
//      if(this.options.placeholderAttr !== 'value') {
//        this.element.removeAttribute(this.options.placeholderAttr);
//      }
//    },
//    initElements: function() {
//      // create fake element if needed
//      if(this.wrapWithElement) {
//        this.fakeElement = document.createElement('span');
//        this.fakeElement.className = this.options.fakeElementClass;
//        this.fakeElement.innerHTML += this.origValue;
//        this.fakeElement.style.color = getStyle(this.element, 'color');
//        this.fakeElement.style.position = 'absolute';
//        this.element.parentNode.insertBefore(this.fakeElement, this.element);
//        
//        if(this.element.value === this.origValue || !this.element.value) {
//          this.element.value = '';
//          this.togglePlaceholderText(true);
//        } else {
//          this.togglePlaceholderText(false);
//        }
//      } else if(!this.element.value && this.origValue.length) {
//        this.element.value = this.origValue;
//      }
//      // get input label
//      if(this.element.id) {
//        this.labels = document.getElementsByTagName('label');
//        for(var i = 0; i < this.labels.length; i++) {
//          if(this.labels[i].htmlFor === this.element.id) {
//            this.labelFor = this.labels[i];
//            break;
//          }
//        }
//      }
//      // get parent node (or parentNode by className)
//      this.elementParent = this.element.parentNode;
//      if(typeof this.options.getParentByClass === 'string') {
//        var el = this.element;
//        while(el.parentNode) {
//          if(hasClass(el.parentNode, this.options.getParentByClass)) {
//            this.elementParent = el.parentNode;
//            break;
//          } else {
//            el = el.parentNode;
//          }
//        }
//      }
//    },
//    attachEvents: function() {
//      this.element.onfocus = bindScope(this.focusHandler, this);
//      this.element.onblur = bindScope(this.blurHandler, this);
//      if(this.options.showUntilTyping) {
//        this.element.onkeydown = bindScope(this.typingHandler, this);
//        this.element.onpaste = bindScope(this.typingHandler, this);
//      }
//      if(this.wrapWithElement) this.fakeElement.onclick = bindScope(this.focusSetter, this);
//    },
//    togglePlaceholderText: function(state) {
//      if(!this.element.readOnly && !this.options.focusOnly) {
//        if(this.wrapWithElement) {
//          this.fakeElement.style.display = state ? '' : 'none';
//        } else {
//          this.element.value = state ? this.origValue : '';
//        }
//      }
//    },
//    focusSetter: function() {
//      this.element.focus();
//    },
//    focusHandler: function() {
//      clearInterval(this.checkerInterval);
//      this.checkerInterval = setInterval(bindScope(this.intervalHandler,this), 1);
//      this.focused = true;
//      if(!this.element.value.length || this.element.value === this.origValue) {
//        if(!this.options.showUntilTyping) {
//          this.togglePlaceholderText(false);
//        }
//      }
//      this.refreshClasses();
//    },
//    blurHandler: function() {
//      clearInterval(this.checkerInterval);
//      this.focused = false;
//      if(!this.element.value.length || this.element.value === this.origValue) {
//        this.togglePlaceholderText(true);
//      }
//      this.refreshClasses();
//      PlaceholderInput.refreshAllInputs(this);
//    },
//    typingHandler: function() {
//      setTimeout(bindScope(function(){
//        if(this.element.value.length) {
//          this.togglePlaceholderText(false);
//          this.refreshClasses();
//        }
//      },this), 10);
//    },
//    intervalHandler: function() {
//      if(typeof this.tmpValue === 'undefined') {
//        this.tmpValue = this.element.value;
//      }
//      if(this.tmpValue != this.element.value) {
//        PlaceholderInput.refreshAllInputs(this);
//      }
//    },
//    refreshState: function() {
//      if(this.wrapWithElement) {
//        if(this.element.value.length && this.element.value !== this.origValue) {
//          this.togglePlaceholderText(false);
//        } else if(!this.element.value.length) {
//          this.togglePlaceholderText(true);
//        }
//      }
//      this.refreshClasses();
//    },
//    refreshClasses: function() {
//      this.textActive = this.focused || (this.element.value.length && this.element.value !== this.origValue);
//      this.setStateClass(this.element, this.options.inputFocusClass,this.focused);
//      this.setStateClass(this.elementParent, this.options.parentFocusClass,this.focused);
//      this.setStateClass(this.labelFor, this.options.labelFocusClass,this.focused);
//      this.setStateClass(this.element, this.options.inputActiveClass, this.textActive);
//      this.setStateClass(this.elementParent, this.options.parentActiveClass, this.textActive);
//      this.setStateClass(this.labelFor, this.options.labelActiveClass, this.textActive);
//    },
//    setStateClass: function(el,cls,state) {
//      if(!el) return; else if(state) addClass(el,cls); else removeClass(el,cls);
//    }
//  };
//  
//  // utility functions
//  function convertToArray(collection) {
//    var arr = [];
//    for (var i = 0, ref = arr.length = collection.length; i < ref; i++) {
//      arr[i] = collection[i];
//    }
//    return arr;
//  }
//  function getInputType(input) {
//    return (input.type ? input.type : input.tagName).toLowerCase();
//  }
//  function hasClass(el,cls) {
//    return el.className ? el.className.match(new RegExp('(\\s|^)'+cls+'(\\s|$)')) : false;
//  }
//  function addClass(el,cls) {
//    if (!hasClass(el,cls)) el.className += " "+cls;
//  }
//  function removeClass(el,cls) {
//    if (hasClass(el,cls)) {el.className=el.className.replace(new RegExp('(\\s|^)'+cls+'(\\s|$)'),' ');}
//  }
//  function bindScope(f, scope) {
//    return function() {return f.apply(scope, arguments);};
//  }
//  function getStyle(el, prop) {
//    if (document.defaultView && document.defaultView.getComputedStyle) {
//      return document.defaultView.getComputedStyle(el, null)[prop];
//    } else if (el.currentStyle) {
//      return el.currentStyle[prop];
//    } else {
//      return el.style[prop];
//    }
//  }
// }());
