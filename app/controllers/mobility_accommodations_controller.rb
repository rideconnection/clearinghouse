class MobilityAccommodationsController < ApplicationController
  load_and_authorize_resource :provider
  load_and_authorize_resource :mobility_accommodation, :through => :provider, :shallow => true

  def index
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @mobility_accommodations }
    end
  end

  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @mobility_accommodation }
    end
  end

  def new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @mobility_accommodation }
    end
  end

  def edit
  end

  def create
    respond_to do |format|
      if @mobility_accommodation.save
        format.html { redirect_to provider_mobility_accommodations_url(@mobility_accommodation.provider), notice: 'Mobility Accommodation was successfully created.' }
        format.json { render json: @mobility_accommodation, status: :created, location: @mobility_accommodation }
      else
        format.html { render action: "new" }
        format.json { render json: @mobility_accommodation.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @mobility_accommodation.update_attributes(params[:mobility_accommodation])
        format.html { redirect_to provider_mobility_accommodations_url(@mobility_accommodation.provider), notice: 'Mobility Accommodation was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @mobility_accommodation.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @mobility_accommodation.destroy
    respond_to do |format|
      format.html { redirect_to provider_mobility_accommodations_url(@mobility_accommodation.provider) }
      format.json { head :no_content }
    end
  end
end
