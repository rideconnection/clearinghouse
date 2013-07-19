class EligibilityRequirementsController < ApplicationController
  load_and_authorize_resource :provider
  load_and_authorize_resource :eligibility_requirement, :through => :provider, :shallow => true

  def index
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @eligibility_requirements }
    end
  end

  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @eligibility_requirement }
    end
  end

  def new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @eligibility_requirement }
    end
  end

  def edit
  end

  def create
    respond_to do |format|
      if @eligibility_requirement.save
        format.html { redirect_to edit_eligibility_requirement_url(@eligibility_requirement), notice: 'Eligibility Requirements Group was successfully created.' }
        format.json { render json: @eligibility_requirement, status: :created, location: @eligibility_requirement }
      else
        format.html { render action: "new" }
        format.json { render json: @eligibility_requirement.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @eligibility_requirement.update_attributes(params[:eligibility_requirement])
        format.html { redirect_to edit_eligibility_requirement_url(@eligibility_requirement), notice: 'Eligibility Requirements Group was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @eligibility_requirement.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @eligibility_requirement.destroy
    respond_to do |format|
      format.html { redirect_to provider_eligibility_requirements_url(@eligibility_requirement.provider) }
      format.json { head :no_content }
    end
  end
end
