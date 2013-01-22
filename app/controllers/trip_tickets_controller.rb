class TripTicketsController < ApplicationController
  load_and_authorize_resource :except => :index
  before_filter :setup_locations, :except => [:index, :search]

  # GET /trip_tickets
  # GET /trip_tickets.json
  def index
    # CanCan's accessible_by (used by load_resource) cannot be used with a 
    # block 'can' definition, so we'll do it the old fashioned way.
    # TODO - limit the query or page results
    if current_user.has_role? :site_admin
      @trip_tickets = TripTicket.all
    else
      @trip_tickets = TripTicket.where(:origin_provider_id => ProviderRelationship.partner_ids_for_provider(current_user.provider) + [current_user.provider.id]).all
    end
    authorize! :read_multiple, @trip_tickets
    
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @trip_tickets }
    end
  end

  # GET /trip_tickets/1
  # GET /trip_tickets/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @trip_ticket }
    end
  end

  # GET /trip_tickets/new
  # GET /trip_tickets/new.json
  def new    
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @trip_ticket }
    end
  end

  # POST /trip_tickets
  # POST /trip_tickets.json
  def create
    @trip_ticket = TripTicket.new(params[:trip_ticket])
    @trip_ticket.originator = current_user.provider unless !@trip_ticket.origin_provider_id.blank?
    
    respond_to do |format|
      if @trip_ticket.save
        format.html { redirect_to @trip_ticket, notice: 'Trip ticket was successfully created.' }
        format.json { render json: @trip_ticket, status: :created, location: @trip_ticket }
      else
        format.html { render action: "new" }
        format.json { render json: @trip_ticket.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /trip_tickets/1
  # PUT /trip_tickets/1.json
  def update
    respond_to do |format|
      if @trip_ticket.update_attributes(params[:trip_ticket])
        format.html { redirect_to @trip_ticket, notice: 'Trip ticket was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @trip_ticket.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /trip_tickets/1
  # DELETE /trip_tickets/1.json
  def destroy
    @trip_ticket.destroy

    respond_to do |format|
      format.html { redirect_to trip_tickets_url }
      format.json { head :no_content }
    end
  end
  
  private
  
  def setup_locations
    @trip_ticket.build_customer_address  unless @trip_ticket.customer_address
    @trip_ticket.build_drop_off_location unless @trip_ticket.drop_off_location
    @trip_ticket.build_pick_up_location  unless @trip_ticket.pick_up_location
  end
end