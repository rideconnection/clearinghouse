class TripClaimsController < ApplicationController
  # GET /trip_claims
  # GET /trip_claims.json
  def index
    @trip_claims = TripClaim.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @trip_claims }
    end
  end

  # GET /trip_claims/1
  # GET /trip_claims/1.json
  def show
    @trip_claim = TripClaim.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @trip_claim }
    end
  end

  # GET /trip_claims/new
  # GET /trip_claims/new.json
  def new
    @trip_claim = TripClaim.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @trip_claim }
    end
  end

  # GET /trip_claims/1/edit
  def edit
    @trip_claim = TripClaim.find(params[:id])
  end

  # POST /trip_claims
  # POST /trip_claims.json
  def create
    @trip_claim = TripClaim.new(params[:trip_claim])

    respond_to do |format|
      if @trip_claim.save
        format.html { redirect_to @trip_claim, notice: 'Trip claim was successfully created.' }
        format.json { render json: @trip_claim, status: :created, location: @trip_claim }
      else
        format.html { render action: "new" }
        format.json { render json: @trip_claim.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /trip_claims/1
  # PUT /trip_claims/1.json
  def update
    @trip_claim = TripClaim.find(params[:id])

    respond_to do |format|
      if @trip_claim.update_attributes(params[:trip_claim])
        format.html { redirect_to @trip_claim, notice: 'Trip claim was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @trip_claim.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /trip_claims/1
  # DELETE /trip_claims/1.json
  def destroy
    @trip_claim = TripClaim.find(params[:id])
    @trip_claim.destroy

    respond_to do |format|
      format.html { redirect_to trip_claims_url }
      format.json { head :no_content }
    end
  end
end