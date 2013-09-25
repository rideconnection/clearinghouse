(function($){
  // Declare the rootUrl used for filtering internal links.
  var rootUrl = document.location.protocol + '//' + (document.location.hostname || document.location.host) + (document.location.port ? ':' + document.location.port : '') + '/';
  
  // Helper functions
  var getFragment = function(url, root) { // Grab the fragment and format it how Backbone expects
    var fragment = url;
    if (fragment.indexOf(':') !== -1)
      fragment = fragment.replace(/.*:\/\/[^\/]+/, '');
    if (!fragment.indexOf(root)) fragment = fragment.substr(root.length);
    return fragment.replace(/^[#\/]/, '');
  }
  
  // jQuery selector for tagging internal links
  $.expr[':'].internal = function(obj, index, meta, stack) {
    var url = $(obj).attr('href') || '';
    return (url.substring(0, rootUrl.length) === rootUrl || url.indexOf(':') === -1); // same domain || relative link
  };
  
  $.fn.clickify = function(options) {
    options = $.extend({ 'root': '/' }, options); // Set the root option if your single-page app isn't in the site root
    
    var anchorTags = this.find('a:internal:not(.no-click)');
    
    anchorTags.click(function (event) {
      var $this = $(this),
          url = $this.attr('href');
      
      if (event.which == 2 || event.metaKey)
        return true;
      
      // Make the call to Backbone.History
      // Backbone will call pushState, update the hash or change window.location depending on what our browser supports
      // Regardless, the part you should care about is that your routes are being called.
      Backbone.history.navigate(getFragment(url), { trigger: true });
      
      event.preventDefault();
      return false;
    });
    
    anchorTags.addClass('no-click'); // Mark tags we've already added our event handler to
    
    return this; // chainability
  };
})(jQuery);