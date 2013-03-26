class TripResultsController < ApplicationController
  # GET /trip_results
  # GET /trip_results.json
  def index
    @trip_results = TripResult.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @trip_results }
    end
  end

  # GET /trip_results/1
  # GET /trip_results/1.json
  def show
    @trip_result = TripResult.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @trip_result }
    end
  end

  # GET /trip_results/new
  # GET /trip_results/new.json
  def new
    @trip_result = TripResult.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @trip_result }
    end
  end

  # GET /trip_results/1/edit
  def edit
    @trip_result = TripResult.find(params[:id])
  end

  # POST /trip_results
  # POST /trip_results.json
  def create
    @trip_result = TripResult.new(params[:trip_result])

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
    @trip_result = TripResult.find(params[:id])

    respond_to do |format|
      if @trip_result.update_attributes(params[:trip_result])
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
    @trip_result = TripResult.find(params[:id])
    @trip_result.destroy

    respond_to do |format|
      format.html { redirect_to trip_results_url }
      format.json { head :no_content }
    end
  end
end
