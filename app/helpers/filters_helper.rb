module FiltersHelper

  def filter_mini_form(msg)
    @filter ||= Filter.new(data: params[:trip_ticket_filters])
    <<-EOS.html_safe
    <a class="opener" href="#">#{msg}</a>
    <div class="slide">
      #{ render 'filters/form', return_to: controller_name }
    </div>
    <hr>
    EOS
  end

  # in our saved filter form, we must re-wrap the field names to end up inside the filter[data] hash
  # for example (note the bracket placement):
  #
  # customer_name        --> filter[data][customer_name]
  # claiming_provider[]  --> filter[data][claiming_provider][]
  # trip_time[start]     --> filter[data][trip_time][start]

  def filter_params_to_hidden_fields(filter_params, wrapped_with, skip_empty_values = true)
    hidden_fields = []
    flatten_hash(filter_params).each do |key, value|
      next if skip_empty_values && value.blank?
      value = [value] unless value.is_a?(Array)
      value.each do |v|
        field_name = wrapped_with.present? ? key.sub(/^\w+/, wrapped_with + '[\0]') : key
        hidden_fields << hidden_field_tag(field_name, v.to_s, :id => nil)
      end
    end

    hidden_fields.join("\n").html_safe
  end

  def flatten_hash(hash = params, ancestor_names = [])
    flat_hash = {}
    hash.each do |k, v|
      names = Array.new(ancestor_names)
      names << k
      if v.is_a?(Hash)
        flat_hash.merge!(flatten_hash(v, names))
      else
        key = flat_hash_key(names)
        key += "[]" if v.is_a?(Array)
        flat_hash[key] = v
      end
    end

    flat_hash
  end

  def flat_hash_key(names)
    names = Array.new(names)
    name = names.shift.to_s.dup
    names.each do |n|
      name << "[#{n}]"
    end
    name
  end

end
