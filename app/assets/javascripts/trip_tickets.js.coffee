# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ ->
  dirtyFilterForm = false

  $('form.apply-filter input[type="submit"]').css({ position: 'absolute', left: '-9999px'})

  $('form.apply-filter select').change ->
    $(this).parent('form').submit()

  $('form.form-filter input').change (evt) ->
    dirtyFilterForm = true

  # when the saved filter form is submitted, make sure any modified values in the
  # ad-hoc form are included by wiping out the old hidden fields and replacing them
  $('div.new-filter-form form').submit (evt) ->
    if dirtyFilterForm == true
      $saved_filter_form = $(this)
      $saved_filter_form.children('input[name^="filter[data]"]').remove()
      $.each $('form.form-filter').serializeArray(), (i, field) ->
        if field.name.indexOf('trip_ticket_filters') == 0 && field.value && field.value.length > 0
          new_field_name = field.name.replace(/^trip_ticket_filters/, "filter[data]");
          $saved_filter_form.append('<input type="hidden" value="'+field.value+'" name="'+new_field_name+'">')
