function Services() {
  this.poly = null;
  this.map = null;

  this.update_hours_enabled = function(i) {
    var enabled = $("input#hours-" + i + "-open").is(":checked");
    $("select#start-hour-" + i).prop('disabled', !enabled);
    $("select#end-hour-" + i).prop('disabled', !enabled);
  };

  this.initialize = function() {
    var self = this;

    // Enable/disable behavior for operating hours on form
    for (var i = 0; i < 7; ++i) (function(i) {
        services.update_hours_enabled(i);
        $("input.hours-" + i).click(function(e) {
           services.update_hours_enabled(i);
        });
    })(i);
  }

  this.create_map_editor = function(points) {
    // Initialize maps for service area
    var center = new google.maps.LatLng(39.811, -98.557);
    self.map = new google.maps.Map(document.getElementById("map-definition"), {
      zoom: 3,
      center: center,
      mapTypeId: google.maps.MapTypeId.ROADMAP
    });

    self.poly = new google.maps.Polygon({
      paths: points,
      editable: true,
      strokeColor: "#FF0000",
      strokeOpacity: 0.8,
      strokeWeight: 2,
      fillColor: "#FF0000",
      fillOpacity: 0.35
    });
    if (points.length > 0) {
      var bounds = new google.maps.LatLngBounds();
      var path = self.poly.getPath();
      for (var i = 0; i < path.length; i++) {
        bounds.extend(path.getAt(i));
      }
      self.map.fitBounds(bounds);
    }
    self.poly.setMap(self.map);

    google.maps.event.addListener(self.poly, 'click', function(event) {
      if (event.vertex != undefined) {
        self.poly.getPath().removeAt(event.vertex);
      }
    });

    // Hacky: handle clicks but ignore double clicks
    var update_timeout = null;
    google.maps.event.addListener(self.map, 'click', function(event){
      update_timeout = setTimeout(function(){
        if (self.poly.getPath() == undefined) {
          self.poly.setPath([event.latLng]);
        } else {
          self.poly.getPath().push(event.latLng);
        }
      }, 200);
    });
    google.maps.event.addListener(self.map, 'dblclick', function(event) {
      clearTimeout(update_timeout);
    });

    // Include map polygon when submitting form
    $('form.new_service,form.edit_service').submit(function() {
      var path = self.poly.getPath();
      for (var i = 0; i < path.length; ++i) {
        $('<input />').attr('type', 'hidden')
            .attr('name', 'service_area[' + i + '][lat]')
            .attr('value', path.getAt(i).lat())
            .appendTo(this);
        $('<input />').attr('type', 'hidden')
            .attr('name', 'service_area[' + i + '][lng]')
            .attr('value', path.getAt(i).lng())
            .appendTo(this);
      }
      return true;
    });

    $('#clear-map').click(function() {
      self.poly.setPath([]);
      return false;
    });
  };

  this.create_map_view = function(map_element, points) {
    var center = new google.maps.LatLng(39.811, -98.557);
    var map = new google.maps.Map(map_element, {
      zoom: 3,
      center: center,
      mapTypeId: google.maps.MapTypeId.ROADMAP
    });

    var poly = new google.maps.Polygon({
      paths: points,
      strokeColor: "#FF0000",
      strokeOpacity: 0.8,
      strokeWeight: 2,
      fillColor: "#FF0000",
      fillOpacity: 0.35
    });
    if (points.length > 0) {
      var bounds = new google.maps.LatLngBounds();
      var path = poly.getPath();
      for (var i = 0; i < path.length; i++) {
        bounds.extend(path.getAt(i));
      }
      map.fitBounds(bounds);
    }
    poly.setMap(map);
  }
};
