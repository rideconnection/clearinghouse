require 'trip_tickets_filter'
require 'provider_services_filter'

class TripTicketsController < ApplicationController
  load_and_authorize_resource :except => [:clear_filters, :apply_filters, :claim_multiple, :create_multiple_claims]
  before_filter :compact_array_params, :only => [:create, :update]
  before_filter :providers_for_lists, :except => [:destroy, :index, :rescind, :clear_filters, :claim_multiple, :create_multiple_claims]
  before_filter :setup_locations, :only => [:show, :new, :edit]

  before_filter :only => [:create, :update] do
    allow_blank_time_field(@trip_ticket, :earliest_pick_up_time)
    allow_blank_time_field(@trip_ticket.trip_result, :actual_pick_up_time, :trip_ticket)
    allow_blank_time_field(@trip_ticket.trip_result, :actual_drop_off_time, :trip_ticket)
  end

  include TripTicketsFilter
  include ProviderServicesFilter

  helper_method :trip_ticket_filters_present?

  # GET /trip_tickets
  # GET /trip_tickets.json
  def index
    restore_last_used_filters
    apply_requested_saved_filter
    
    @providers_for_filters = Provider.accessible_by(current_ability)
    @trip_tickets = trip_tickets_filter(@trip_tickets, current_user.provider)

    service_filter_options = { ignore_eligibility: ignore_service_filters? }
    @trip_tickets = provider_services_filter(@trip_tickets, current_user.provider, service_filter_options)
    
    @trip_ticket = @trip_tickets.where(:id => params[:id]).first || @trip_tickets.first

    massage_trip_ticket_trip_time_filter_values_for_form

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: trip_ticket_collection_as_json_for_backbone }
    end
  end
  
  # GET /trip_tickets/clear_filters
  # GET /trip_tickets/clear_filters.json
  # While it isn't optimal to be changing state via a GET request, it is going
  # to be easier in the long run since we need to both redirect here from the
  # FiltersController, and send AJAX requests here from the dashboard.
  def clear_filters
    cookies.delete(:last_used_filters)
    
    return_to = params[:return_to] || trip_tickets_url
    respond_to do |format|
      format.html { redirect_to return_to, notice: 'Trip ticket filters cleared.' }
      format.json { render json: {
        saved_filter_form: {
          rendered_partial: view_context.filter_mini_form("Save current filters")
        }
      }.to_json }
    end    
  end

  # GET /trip_tickets/apply_filters
  # GET /trip_tickets/apply_filters.json
  # While it isn't optimal to be changing state via a GET request, it is going
  # to be easier in the long run since we need to both redirect here from the
  # FiltersController, and send AJAX requests here from the dashboard.
  def apply_filters
    apply_requested_saved_filter
    save_last_used_filters

    return_to = params[:return_to] || trip_tickets_url
    respond_to do |format|
      
      format.html { redirect_to return_to }
      format.json { render_with_format json: {
        saved_filter_form: {
          rendered_partial: view_context.filter_mini_form(@filter.present? ? "Update saved filter" : "Save current filters")
        }
      }.to_json }
    end    
  end

  # GET /trip_tickets/1
  # GET /trip_tickets/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: trip_ticket_instance_as_json_for_backbone }
    end
  end

  # GET /trip_tickets/new
  # GET /trip_tickets/new.json
  def new    
    @trip_ticket.originator = current_user.provider
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: { rendered_partial: render_to_string(partial: "trip_tickets/form", formats: [:html]) }.to_json }
    end
  end
  
  # GET /trip_tickets/1/edit
  def edit
    respond_to do |format|
      format.html { render action: "show" }
      format.json { render json: { rendered_partial: render_to_string(partial: "trip_tickets/form", formats: [:html]) }.to_json }
    end
  end

  # POST /trip_tickets
  # POST /trip_tickets.json
  def create
    @trip_ticket = TripTicket.new(params[:trip_ticket])
    @trip_ticket.originator = current_user.provider
    
    respond_to do |format|
      if @trip_ticket.save
        format.html { redirect_to @trip_ticket, notice: 'Trip ticket was successfully created.' }
        format.json { render json: @trip_ticket, status: :created, location: @trip_ticket }
      else
        setup_locations
        format.html { render action: "new" }
        format.json { render json: {rendered_partial: render_to_string(partial: "shared/error_explanation", locals: { object: @trip_ticket }, formats: [:html])}.to_json, status: :unprocessable_entity }
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
        setup_locations
        format.html { render action: "edit" }
        format.json { render json: {rendered_partial: render_to_string(partial: "shared/error_explanation", locals: { object: @trip_ticket }, formats: [:html])}.to_json, status: :unprocessable_entity }
      end
    end
  end

  def rescind
    @trip_ticket.rescind!

    respond_to do |format|
      format.html { redirect_to @trip_ticket, notice: 'Trip ticket was successfully rescinded.' }
      format.json { head :no_content }
    end
  end
  
  def claim_multiple
    selected_ids = Array(params[:trip_ticket].try(:[], :selected_ids))
    @trip_claims = []
    TripTicket.accessible_by(current_ability).where(id: selected_ids).select{|t| t.claimable_by?(current_user)}.each do |tt|
      trip_claim = tt.trip_claims.new
      trip_claim.claimant = current_user.provider
      trip_claim.status = :pending
      @trip_claims << trip_claim
    end
    
    respond_to do |format|
      format.html # claim_multiple.html.erb
      format.json { render json: { rendered_partial: render_to_string(partial: "trip_tickets/claim_multiple", formats: [:html]) }.to_json }
    end
  end

  def create_multiple_claims
    trip_ticket_ids = Array(params[:trip_claim].try(:keys))
    trip_tickets = TripTicket.accessible_by(current_ability).where(id: trip_ticket_ids).select{|t| t.claimable_by?(current_user)}
    
    trip_claim_errors = false
    @trip_claims = []
    TripClaim.transaction do
      trip_tickets.each do |tt|
        trip_claim = tt.trip_claims.new(params[:trip_claim][tt.id.to_s])
        trip_claim.claimant = current_user.provider
        trip_claim.status = :pending
        @trip_claims << trip_claim
        unless trip_claim.save
          trip_claim_errors = true
        end
      end
      
      raise ActiveRecord::Rollback if trip_claim_errors
    end
    
    respond_to do |format|
      unless trip_claim_errors
        format.html { redirect_to trip_tickets_path, notice: 'Selected trips were successfully claimed.' }
        format.json { head :no_content }
      else
        format.html { render action: "claim_multiple", alert: 'Could not save all trip claims.' }
        format.json { render json: @trip_claims.collect(&:errors).to_json, status: :unprocessable_entity }
      end
    end
    
  end
  
  private
  
  def setup_locations
    @trip_ticket.build_customer_address  unless @trip_ticket.customer_address
    @trip_ticket.build_drop_off_location unless @trip_ticket.drop_off_location
    @trip_ticket.build_pick_up_location  unless @trip_ticket.pick_up_location
    @result = @trip_ticket.make_result_for_form
  end
  
  def compact_array_params
    TripTicket::CUSTOMER_IDENTIFIER_ARRAY_FIELD_NAMES.each do |field_sym|
      params[:trip_ticket][field_sym].try(:reject!) {|v| v.blank? }
    end
    params[:trip_ticket][:provider_white_list].try(:reject!) {|v| v.blank?}
    params[:trip_ticket][:provider_black_list].try(:reject!) {|v| v.blank?}
  end

  def apply_requested_saved_filter
    @filter = Filter.find_by_name(params[:saved_filter]) if params[:saved_filter].present?
    if @filter
      new_params = @filter.data
      # support combining a named filter with ad-hoc filters
      new_params.merge!(params[:trip_ticket_filters]) if trip_ticket_filters_present?
      params[:trip_ticket_filters] = new_params
    end
  end

  def save_last_used_filters
    # This shouldn't ever be true, but just in case
    unless params[:trip_ticket_filters] == 'clear'
      values = {}
      values[:trip_ticket_filters] = params[:trip_ticket_filters] if params[:trip_ticket_filters].present?
      values[:saved_filter] = params[:saved_filter] if params[:saved_filter].present?
      logger.debug "Saving current parameters in last_used_filters cookie: #{values}"
      cookies[:last_used_filters] = { value: values.to_json }
    end
  end

  def restore_last_used_filters
    filters = cookies[:last_used_filters]
    logger.debug "Retrieved value of last_used_filters cookie: #{filters || 'nil'}"
    begin
      new_params = JSON.parse(filters).with_indifferent_access
      params[:saved_filter] = new_params[:saved_filter] if new_params[:saved_filter].present?
      params[:trip_ticket_filters] = new_params[:trip_ticket_filters] if new_params[:trip_ticket_filters].present?
    rescue
      logger.error "Ignoring invalid last_used_filters cookie: #{filters || 'nil'}, class #{filters.class}"
      cookies.delete(:last_used_filters)
    end
  end

  def massage_trip_ticket_trip_time_filter_values_for_form
    params[:trip_ticket_filters][:trip_time][:start] = parse_trip_ticket_trip_time(params[:trip_ticket_filters][:trip_time][:start], nil).try(:strftime, "%Y-%m-%d %I:%M %P")
    params[:trip_ticket_filters][:trip_time][:end]   = parse_trip_ticket_trip_time(params[:trip_ticket_filters][:trip_time][:end], nil).try(:strftime, "%Y-%m-%d %I:%M %P")
  end
  
  def providers_for_lists
    # This list needs to be based on the originating provider, not the current user
    @providers_for_lists = Provider.where(:id => ProviderRelationship.partner_ids_for_provider(current_user.provider))
  end

  def ignore_service_filters?
    params[:trip_ticket_filters].try(:[], :service_filters) != 'apply_service_filters'
  end
  
  # Rendering the entire collection as JSON is dangerous as we could be exposing information
  # to provider users that shouldn't have access to some attributes. Additionally, we are
  # using a lot of complex helper and model methods to render this data to the end user,
  # often conditionally based on who is logged in. As such, it is going to be much more
  # simple to pass rendered Rails views to Backbone rather than use javascript templates
  # via Backbone.
  
  def trip_ticket_collection_as_json_for_backbone
    trip_tickets = []
    @trip_tickets.each do |trip_ticket|
      trip_tickets << {
        id: trip_ticket.id,
        updated_at: trip_ticket.updated_at.to_f,
        downcased_status: trip_ticket.status.downcase,
        primary_ordering_timestamp: trip_ticket.appointment_time.to_f,
        secondary_ordering_timestamp: trip_ticket.created_at.to_f,
        rendered_partial: render_to_string(partial: "trip_tickets/ajaxified_dashboard/trip_ticket_list_item", locals: {trip_ticket: trip_ticket}, formats: [:html]),
      }
    end
    trip_tickets.to_json
  end
  
  def trip_ticket_instance_as_json_for_backbone
    {
      id: @trip_ticket.id,
      updated_at: @trip_ticket.updated_at.to_f,
      rendered_partial: render_to_string(partial: "trip_tickets/ajaxified_dashboard/trip_ticket_details", locals: {trip_ticket: @trip_ticket}, formats: [:html]),
    }.to_json
  end
end
