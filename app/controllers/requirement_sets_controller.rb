class RequirementSetsController < ApplicationController
  load_and_authorize_resource :provider
  load_and_authorize_resource :requirement_set, :through => :provider, :shallow => true

  def index
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @requirement_sets }
    end
  end

  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @requirement_set }
    end
  end

  def new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @requirement_set }
    end
  end

  def edit
  end

  def create
    respond_to do |format|
      if @requirement_set.save
        format.html { redirect_to edit_requirement_set_url(@requirement_set), notice: 'Eligibility Requirements Group was successfully created.' }
        format.json { render json: @requirement_set, status: :created, location: @requirement_set }
      else
        format.html { render action: "new" }
        format.json { render json: @requirement_set.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @requirement_set.update_attributes(params[:requirement_set])
        format.html { redirect_to edit_requirement_set_url(@requirement_set), notice: 'Eligibility Requirements Group was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @requirement_set.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @requirement_set.destroy
    respond_to do |format|
      format.html { redirect_to provider_requirement_sets_url(@requirement_set.provider) }
      format.json { head :no_content }
    end
  end
end
