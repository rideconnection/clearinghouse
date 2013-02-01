# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$(document).ready -> 
  $("#ethnicity_selection").change ->
    new_value = $(this).find("option:selected").val()
    $("#trip_ticket_customer_ethnicity").val(new_value)

