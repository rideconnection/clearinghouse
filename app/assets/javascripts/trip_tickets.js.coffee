# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$(document).ready -> 
  fillTextWithOption("#trip_ticket_customer_ethnicity", "#ethnicity_selection")
  fillTextWithOption("#trip_ticket_customer_race", "#race_selection")

fillTextWithOption = (text_input_selector, select_input_selector) ->
  $(select_input_selector).change ->
    new_value = $(this).find("option:selected").val()
    $(text_input_selector).val(new_value)
  
