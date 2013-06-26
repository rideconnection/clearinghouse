module FiltersHelper

  def filter_mini_form(msg)
    @filter ||= Filter.new(data: params[:trip_ticket_filters])
    <<-EOS.html_safe
    <a class="opener" href="#">#{msg}</a>
    <div class="slide">
      #{ render 'filters/form', return_to: controller_name }
      <div id="saved-filter-message"></div>
    </div>
    <hr>
    EOS
  end

end
