class MobilityAccommodationsController < ApplicationController
  load_and_authorize_resource :service, :shallow => true
  load_and_authorize_resource :mobility_accommodation, :through => :service, :shallow => true

  def index
    @provider = Provider.find(params[:provider_id])
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
    @form_path = [ @service.provider, @service, @mobility_accommodation ]
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @mobility_accommodation }
    end
  end

  def edit
    @form_path = @mobility_accommodation
  end

  def create
    respond_to do |format|
      if @mobility_accommodation.save
        @form_path = @mobility_accommodation
        format.html { redirect_to edit_mobility_accommodation_url(@mobility_accommodation), notice: 'Mobility Accommodation was successfully created.' }
        format.json { render json: @mobility_accommodation, status: :created, location: @mobility_accommodation }
      else
        @form_path = [ @service.provider, @service, @mobility_accommodation ]
        format.html { render action: "new" }
        format.json { render json: @mobility_accommodation.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @form_path = @mobility_accommodation
    respond_to do |format|
      if @mobility_accommodation.update_attributes(params[:mobility_accommodation])
        format.html { redirect_to edit_mobility_accommodation_url(@mobility_accommodation), notice: 'Mobility Accommodation was successfully updated.' }
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
      format.html { redirect_to provider_path(@mobility_accommodation.service.provider) + "#service-#{ @mobility_accommodation.service.id }-mobility-accommodations" }
      format.json { head :no_content }
    end
  end
end
