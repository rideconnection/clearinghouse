class ProviderRelationshipsController < ApplicationController
  load_and_authorize_resource

  # GET /provider_relationships/1
  # GET /provider_relationships/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @provider_relationship }
    end
  end

  # GET /provider_relationships/new
  # GET /provider_relationships/new.json
  def new
    @provider = Provider.find(params[:provider_id])

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @provider_relationship }
    end
  end

  # GET /provider_relationships/1/edit
  def edit
  end

  # POST /provider_relationships
  # POST /provider_relationships.json
  def create
    respond_to do |format|
      if @provider_relationship.save
        format.html do 
          redirect_to @provider_relationship.requesting_provider, 
            notice: 'Provider relationship was successfully created.'
        end
        format.json do 
          render(
            json: @provider_relationship, 
            status: :created, 
            location: @provider_relationship
          )
        end
      else
        format.html { render action: "new" }
        format.json do 
          render json: @provider_relationship.errors, status: :unprocessable_entity
        end
      end
    end
  end

  # PUT /provider_relationships/1
  # PUT /provider_relationships/1.json
  def update
    respond_to do |format|
      if @provider_relationship.update_attributes(params[:provider_relationship])
        format.html do 
          redirect_to provider_for_request, 
            notice: 'Provider relationship was successfully updated.'
        end
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json do 
          render json: @provider_relationship.errors, status: :unprocessable_entity
        end
      end
    end
  end

  # DELETE /provider_relationships/1
  # DELETE /provider_relationships/1.json
  def destroy
    @provider = provider_for_request
    @provider_relationship.destroy

    respond_to do |format|
      format.html { redirect_to @provider, notice: 'Provider relationship destroyed!'}
      format.json { head :no_content }
    end
  end

  def activate
    @provider_relationship = ProviderRelationship.find(
      params[:provider_relationship_id])
    @provider_relationship.approve!
    respond_to do |format|
      format.html do 
        redirect_to @provider_relationship.cooperating_provider, 
          notice: 'Provider relationship activated!'
      end
      format.json { head :no_content }
    end
  end

  private

  def provider_for_request
    if can? :update, @provider_relationship.requesting_provider
      @provider_relationship.requesting_provider
    else
      @provider_relationship.cooperating_provider
    end
  end
end
