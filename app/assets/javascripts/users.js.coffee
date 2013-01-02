# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$(document).ready -> 
  $("#user_must_generate_password").click ->
    new_value = $("#user_must_generate_password").prop("checked")
    $("#user_password, #user_password_confirmation").prop("disabled", new_value)
