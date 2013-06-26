# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ ->
  dirtyFilterForm = false

  $('form.apply-filter input[type=submit]').css({ position: 'absolute', left: '-9999px'})

  $('form.apply-filter select').change ->
    $(this).parent('form').submit()

  $('form.form-filter input').change (evt) ->
    dirtyFilterForm = true
    $('#saved-filter-message').text("Click 'Search' to apply your changes before saving the filter.")

  $('form.new_filter, form.edit_filter').submit (evt) ->
    if dirtyFilterForm == true
      response = confirm("You have filter changes that have not been applied. Press OK to save the filter without these changes:")
      if (response != true)
        evt.preventDefault()
