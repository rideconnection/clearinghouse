class EligibilityRequirementsController < ApplicationController
  load_and_authorize_resource :service, :shallow => true
  load_and_authorize_resource :eligibility_requirement, :through => :service, :shallow => true

  def index
    @provider = Provider.find(params[:provider_id])
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
    @form_path = [ @service.provider, @service, @eligibility_requirement ]
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @eligibility_requirement }
    end
  end

  def edit
    @form_path = @eligibility_requirement
  end

  def create
    respond_to do |format|
      if @eligibility_requirement.save
        @form_path = @eligibility_requirement
        format.html { redirect_to edit_eligibility_requirement_url(@eligibility_requirement), notice: 'Eligibility Requirements Group was successfully created.' }
        format.json { render json: @eligibility_requirement, status: :created, location: @eligibility_requirement }
      else
        @form_path = [ @service.provider, @service, @eligibility_requirement ]
        format.html { render action: "new" }
        format.json { render json: @eligibility_requirement.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @form_path = @eligibility_requirement
    respond_to do |format|
      if @eligibility_requirement.update_attributes(eligibility_requirement_params)
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
      format.html { redirect_to provider_path(@eligibility_requirement.service.provider) + "#service-#{ @eligibility_requirement.service.id }-eligibility-requirements" }
      format.json { head :no_content }
    end
  end

  private

  def eligibility_requirement_params
    params.require(:eligibility_requirement).permit(:boolean_type, eligibility_rules_attributes: [
      :id, :eligibility_requirement_id, :trip_field, :comparison_type, :comparison_value, :_destroy
    ])
  end
end
