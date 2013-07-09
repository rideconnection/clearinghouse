# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

class window.TripTicketsMap
  map = null
  mapOptions =
    zoom: 8
    mapTypeId: google.maps.MapTypeId.ROADMAP
  pickUpLocation = null
  dropOffLocation = null
  
  setPickUpLocation: (location) ->
    console.log 'setPickUpLocation'
    pickUpLocation = location

  setDropOffLocation: (location) ->
    console.log 'setDropOffLocation'
    dropOffLocation = location

  init: (pickUpLocationAddress, dropOffLocationAddress) ->
    console.log 'init'
    debugger
    @locateAddress(pickUpLocationAddress, @setPickUpLocation)
    @locateAddress(dropOffLocationAddress, @setDropOffLocation, true)
  
  showTwoPoints: ->
    console.log 'showTwoPoints'
    if pickUpLocation? and dropOffLocation?    
      mapOptions.center = new google.maps.LatLng(
        (pickUpLocation.geometry.location.lat()+dropOffLocation.geometry.location.lat())/2,
        (pickUpLocation.geometry.location.lng()+dropOffLocation.geometry.location.lng())/2
      )
      console.log 'mapOptions', mapOptions
      @showMap()
      console.log 'map', map
      console.log 'google.maps.DirectionsService'
      directionsService = new google.maps.DirectionsService()
      console.log 'google.maps.DirectionsRenderer'
      directionsDisplay = new google.maps.DirectionsRenderer(
        # suppressMarkers: true,
        # suppressInfoWindows: true
      )
      console.log 'directionsDisplay.setMap'
      console.log 'directionsDisplay.setMap'
      directionsDisplay.setMap(map)
      request =
        origin: pickUpLocation.geometry.location
        destination: dropOffLocation.geometry.location
        travelMode: google.maps.DirectionsTravelMode.DRIVING
      console.log 'directionsService.route'
      directionsService.route request, (response, status) =>
        console.log 'inside directionsService.route', response
        if status == google.maps.DirectionsStatus.OK
          console.log 'directionsDisplay.setDirections'
          directionsDisplay.setDirections(response)
      ###
      line = new google.maps.Polyline(
        map: map,
        path: [pickUpLocation, dropOffLocation],
        strokeWeight: 7,
        strokeOpacity: 0.8,
        strokeColor: "#FFAA00"
      )
      ###
    else 
      if pickUpLocation?
        mapOptions.center = pickUpLocation.geometry.location
      else if dropOffLocation?
        mapOptions.center = dropOffLocation.geometry.location
      
      @showMap()
    
    return @map
  
  locateAddress: (address, setter, lastAddressFetched = false) ->
    console.log 'locateAddress', address
    geocoder = new google.maps.Geocoder()
    geocoder.geocode address, (results, status) =>
      console.log results
      if status == google.maps.GeocoderStatus.OK
        setter results[0]
      else
        alert("Unable to locate address for the following reason: " + status);
        setter null
        
      @showTwoPoints() if lastAddressFetched
  
  showMap: ->
    console.log 'showMap'
    map = new google.maps.Map $("#map-canvas")[0], mapOptions

$ ->
  dirtyFilterForm = false

  $('form.apply-filter input[type="submit"]').css({ position: 'absolute', left: '-9999px'})

  $('form.apply-filter select').change ->
    $(this).parent('form').submit()

  $('form.form-filter input,form.form-filter select').change (evt) ->
    dirtyFilterForm = true

  # when the saved filter form is submitted, make sure any modified values in the
  # ad-hoc form are included by wiping out the old hidden fields and replacing them
  $('div.saved-filter-form form').submit (evt) ->
    if dirtyFilterForm == true
      $saved_filter_form = $(this)
      $saved_filter_form.children('input[name^="filter[data]"]').remove()
      $.each $('form.form-filter').serializeArray(), (i, field) ->
        if field.name.indexOf('trip_ticket_filters') == 0 && field.value && field.value.length > 0
          new_field_name = field.name.replace(/^trip_ticket_filters/, "filter[data]");
          $saved_filter_form.append('<input type="hidden" value="'+field.value+'" name="'+new_field_name+'">')
