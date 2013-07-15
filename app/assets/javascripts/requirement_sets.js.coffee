$ ->
  lastRow = $('table#eligibility-requirements-list tbody tr').last().html()

  if lastRow
    lastRowId = parseInt(lastRow.match(/eligibility_requirements_attributes_(\d+)/i)[1])

    $('#eligibility-requirements-list-add').click (evt) ->
      evt.preventDefault();
      lastRowId += 1
      newRow = lastRow.replace(/eligibility_requirements_attributes_\d+/g, 'eligibility_requirements_attributes_' + lastRowId)
      newRow = newRow.replace(/\[eligibility_requirements_attributes\]\[\d+\]/g, '[eligibility_requirements_attributes][' + lastRowId + ']')
      $('table#eligibility-requirements-list tbody').append('<tr>' + newRow + '</tr>')

    $('#eligibility-requirements-list-submit').click (evt) ->
      evt.preventDefault();
      $('table#eligibility-requirements-list tbody tr').each (row_index, row) ->
        $('select,input', row).each (field_index, field) ->
          unless $(field).val()
            $(row).remove()
      $(this).closest('form').submit()
