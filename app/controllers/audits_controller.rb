class AuditsController < ApplicationController
  load_and_authorize_resource :trip_ticket

  def index
    @audits = @trip_ticket.audits
    respond_to do |format|
      #format.html # index.html.erb
      #format.json { render json: @audits }
      format.js
    end
  end
end
