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
//= require jquery-ui-1.10.3.custom.min
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

// Session idle/timeout functionality. H/T to jquery.idletimer.js
var SessionTimer = function(user_options) {
  var options = $.extend({
    // Countdown duration in seconds
    countdown_length: 30,

    // Buffer to handle discrepancy between server timeout and local timeout
    session_buffer: 15
  }, user_options);
  var timer = null;
  var countdown = null;
  var self = this;

  $("#session-resume").bind("click", function(e) {
    e.preventDefault();
    self.onResume();
  });

  // Start the timer
  this.start = function() {
    self.checkSession(function(session_timeout) {
      var idle_timeout = session_timeout - options.countdown_length -
                         options.session_buffer + 1;
      timer = window.setTimeout(function() {self.onIdle()}, idle_timeout*1000);
    });
  };

  // Request the time remaining from the server
  this.checkSession = function(onSuccess) {
    $.ajax({
      timeout: 5000,
      url: ClearingHouse.urls['check_session'],
      headers: {
        // Do not update last_request_at when checking session timeout, which
        // would defeat the purpose of this script.
        'devise.skip_trackable': 1
      },
      error: function() {
        // Not sure if there's anything useful to do here.
      },
      success: function(data) {
        onSuccess(data["timeout_in"]);
      }
    });
  };

  this.touchSession = function(onSuccess) {
    $.ajax({
      timeout: 5000,
      url: ClearingHouse.urls['touch_session'],
      error: function() {
        // Not sure if there's anything useful to do here.
      },
      success: onSuccess
    });
  }

  this.startCountdown = function() {
    var counter = options.countdown_length;
    $("#session-timeout-warning span").html(counter);
    $("#session-timeout-warning").slideDown();

    countdown = window.setInterval(function() {
      if (--counter === 0) {
        window.clearInterval(countdown);
        self.onTimeout();
      } else {
        $("#session-timeout-warning span").html(counter);
      }
    }, 1000);
  };

  this.stopCountdown = function() {
    $("#session-timeout-warning").slideUp();
    window.clearInterval(countdown);
    countdown = null;
  };

  this.onIdle = function() {
    self.checkSession(function(session_timeout) {
      if (session_timeout <= options.countdown_length+options.session_buffer) {
        self.startCountdown();
      } else {
        self.start();
      }
    });
  };

  this.onResume = function() {
    self.stopCountdown();
    self.touchSession(function() {
      self.start();
    });
  };

  this.onTimeout = function() {
    // One last check to see if the session has been woken up in another tab
    self.checkSession(function(timeout) {
      if (timeout <= options.session_buffer) {
        window.location.href = ClearingHouse.urls['sign_out'];
      } else {
        self.stopCountdown();
        self.start();
      }
    });
  };
};

// open-close init
function initOpenClose(scope) {
  scope = scope || $(document);
  scope.find('.details-box').openClose({
    activeClass: 'active',
    opener: '.opener',
    slider: '.slide',
    animSpeed: 400,
    effect: 'slide'
  });
  scope.find('.form-holder').openClose({
    activeClass: 'active',
    opener: '.opener',
    slider: '.slide',
    animSpeed: 400,
    effect: 'slide'
  });
}

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

// Avoid `console` errors in browsers that lack a console.
// Source: Twitter's source code
(function() {
  var method;
  var noop = function () {};
  var methods = [
    'assert', 'clear', 'count', 'debug', 'dir', 'dirxml', 'error',
    'exception', 'group', 'groupCollapsed', 'groupEnd', 'info', 'log',
    'markTimeline', 'profile', 'profileEnd', 'table', 'time', 'timeEnd',
    'timeStamp', 'trace', 'warn'
  ];
  var length = methods.length;
  var console = (window.console = window.console || {});

  while (length--) {
    method = methods[length];

    // Only stub undefined methods.
    if (!console[method]) {
      console[method] = noop;
    }
  }
}());
