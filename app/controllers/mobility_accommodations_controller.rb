class MobilityAccomodationsController < ApplicationController
  load_and_authorize_resource :provider
  load_and_authorize_resource :mobility_accomodation, :through => :provider, :shallow => true

  def index
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @mobility_accomodations }
    end
  end

  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @mobility_accomodation }
    end
  end

  def new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @mobility_accomodation }
    end
  end

  def edit
  end

  def create
    respond_to do |format|
      if @mobility_accomodation.save
        format.html { redirect_to provider_mobility_accomodations_url(@mobility_accomodation.provider), notice: 'Mobility Accomodation was successfully created.' }
        format.json { render json: @mobility_accomodation, status: :created, location: @mobility_accomodation }
      else
        format.html { render action: "new" }
        format.json { render json: @mobility_accomodation.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @mobility_accomodation.update_attributes(params[:mobility_accomodation])
        format.html { redirect_to provider_mobility_accomodations_url(@mobility_accomodation.provider), notice: 'Mobility Accomodation was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @mobility_accomodation.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @mobility_accomodation.destroy
    respond_to do |format|
      format.html { redirect_to provider_mobility_accomodations_url(@mobility_accomodation.provider) }
      format.json { head :no_content }
    end
  end
end
