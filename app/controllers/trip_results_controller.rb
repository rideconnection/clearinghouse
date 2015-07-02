class TripResultsController < ApplicationController
  load_and_authorize_resource :trip_ticket
  load_and_authorize_resource :trip_result, :through => :trip_ticket, :singleton => true

  before_filter :only => [:create, :update] do
    allow_blank_time_field(@trip_result, :actual_pick_up_time)
    allow_blank_time_field(@trip_result, :actual_drop_off_time)
  end

  # GET /trip_results
  # GET /trip_results.json
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @trip_results }
    end
  end

  # GET /trip_results/1
  # GET /trip_results/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @trip_result }
      format.js
    end
  end

  # GET /trip_results/new
  # GET /trip_results/new.json
  def new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @trip_result }
    end
  end

  # GET /trip_results/1/edit
  def edit; end

  # POST /trip_results
  # POST /trip_results.json
  def create
    respond_to do |format|
      if @trip_result.save
        format.html { redirect_to @trip_result.trip_ticket, notice: 'Trip result was successfully created.' }
        format.json { render json: @trip_result, status: :created, location: @trip_result }
      else
        message = "Problem saving trip results: " + 
          @trip_result.errors.full_messages.join("; ")
        format.html { redirect_to @trip_result.trip_ticket, alert: message }
        format.json { render json: @trip_result.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /trip_results/1
  # PUT /trip_results/1.json
  def update
    respond_to do |format|
      if @trip_result.update_attributes(trip_result_params)
        format.html { redirect_to @trip_result.trip_ticket, notice: 'Trip result was successfully updated.' }
        format.json { head :no_content }
      else
        message = "Problem saving trip results: " + 
          @trip_result.errors.full_messages.join("; ")
        format.html { redirect_to @trip_result.trip_ticket, alert: message }
        format.json { render json: @trip_result.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /trip_results/1
  # DELETE /trip_results/1.json
  def destroy
    @trip_result.destroy

    respond_to do |format|
      format.html { redirect_to trip_results_url }
      format.json { head :no_content }
    end
  end

  private

  def trip_result_params
    params.require(:trip_result).permit(:actual_drop_off_time, :actual_pick_up_time, :base_fare,
      :billable_mileage, :driver_id, :extra_securement_count, :fare, :fare_type, :miles_traveled,
      :odometer_end, :odometer_start, :outcome, :rate, :rate_type, :trip_claim_id, :trip_ticket_id,
      :vehicle_id, :vehicle_type, :notes)
  end
end
