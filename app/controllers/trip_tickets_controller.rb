require 'trip_tickets_filter'

class TripTicketsController < ApplicationController
  load_and_authorize_resource
  before_filter :compact_array_params, :only => [:create, :update]
  before_filter :providers_for_lists, :except => [:destroy, :index]
  before_filter :setup_locations, :except => :index

  include TripTicketsFilter

  # GET /trip_tickets
  # GET /trip_tickets.json
  def index
    restore_or_save_last_used_filters
    @providers_for_filters = Provider.accessible_by(current_ability)
    @trip_tickets = trip_tickets_filter(@trip_tickets)
    massage_trip_ticket_trip_time_filter_values_for_form

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
      format.js
    end
  end

  # GET /trip_tickets/new
  # GET /trip_tickets/new.json
  def new    
    @trip_ticket.originator = current_user.provider
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @trip_ticket }
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

  def rescind
    @trip_ticket.rescind!

    respond_to do |format|
      format.html { redirect_to @trip_ticket, notice: 'Trip ticket was successfully rescinded.' }
      format.json { head :no_content }
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

  def restore_or_save_last_used_filters
    if params[:trip_ticket_filters].present?
      if params[:trip_ticket_filters] == 'clear'
        logger.debug "Clearing last_used_filters cookie"
        cookies.delete(:last_used_filters)
        params[:trip_ticket_filters] = nil
      elsif params[:trip_ticket_filters].is_a?(Hash)
        logger.debug "Saving current parameters in last_used_filters cookie: #{params[:trip_ticket_filters] || 'nil'}"
        cookies[:last_used_filters] = { value: params[:trip_ticket_filters].to_json }
      else
        logger.debug "Format of params[:trip_ticket_filters] not recognized, last_used_filters cookie not saved"
      end
    else
      filters = cookies[:last_used_filters]
      logger.debug "Retrieved value of last_used_filters cookie: #{filters || 'nil'}"
      begin
        params[:trip_ticket_filters] = JSON.parse(filters).with_indifferent_access if filters.present?
      rescue
        logger.error "Ignoring invalid last_used_filters cookie: #{filters || 'nil'}, class #{filters.class}"
        cookies.delete(:last_used_filters)
      end
    end
  end

  def massage_trip_ticket_trip_time_filter_values_for_form
    params[:trip_ticket_filters][:trip_time][:start] = parse_trip_ticket_trip_time(params[:trip_ticket_filters][:trip_time][:start], nil).try(:strftime, "%Y-%m-%d %I:%M %P")
    params[:trip_ticket_filters][:trip_time][:end]   = parse_trip_ticket_trip_time(params[:trip_ticket_filters][:trip_time][:end], nil).try(:strftime, "%Y-%m-%d %I:%M %P")
  end
  
  def providers_for_lists
    @providers_for_lists = Provider.accessible_by(current_ability) - [current_user.provider]
  end
end
