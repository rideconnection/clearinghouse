class TripTicketsController < ApplicationController
  load_and_authorize_resource
  before_filter :setup_locations, :except => :index

  # GET /trip_tickets
  # GET /trip_tickets.json
  def index
    init_trip_ticket_trip_time_filter_values
    
    (params[:trip_ticket_filters] ||= Hash.new).each do |filter,value|
      case filter.to_sym
      when :seats_required
        @trip_tickets = @trip_tickets.filter_by_seats_required(value) unless value.try(:[], "min").blank? && value.try(:[], "max").blank?
      when :trip_time
        unless value[:start][:hour].blank? && value[:start][:minute].blank? && value[:end][:hour].blank? && value[:end][:minute].blank?
          start_hour   = value[:start][:hour].present?   ? value[:start][:hour]   : '00'
          start_minute = value[:start][:minute].present? ? value[:start][:minute] : '00'
          end_hour     = value[:end][:hour].present?     ? value[:end][:hour]     : '00'
          end_minute   = value[:end][:minute].present?   ? value[:end][:minute]   : '00'
          @trip_tickets = @trip_tickets.filter_by_trip_time({:start => "#{start_hour}:#{start_minute}", :end => "#{end_hour}:#{end_minute}"})
        end
      else
        if !value.blank? && TripTicket.respond_to?("filter_by_#{filter.to_s}")
          @trip_tickets = @trip_tickets.send("filter_by_#{filter.to_s}", value)
        end
      end
    end

    @providers_for_filters = Provider.accessible_by(current_ability)
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
    end
  end

  # GET /trip_tickets/new
  # GET /trip_tickets/new.json
  def new    
    @trip_ticket.originator = current_user.provider unless current_user.has_admin_role?
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @trip_ticket }
    end
  end

  # POST /trip_tickets
  # POST /trip_tickets.json
  def create
    compact_string_array_params

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
    compact_string_array_params

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
  
  def compact_string_array_params
    TripTicket::ARRAY_FIELD_NAMES.each do |field_sym|
      params[:trip_ticket][field_sym].try(:reject!) {|v| v.blank? } 
    end
  end
  
  def init_trip_ticket_trip_time_filter_values
    params[:trip_ticket_filters]                     ||= Hash.new
    params[:trip_ticket_filters][:trip_time]         ||= Hash.new
    params[:trip_ticket_filters][:trip_time][:start] ||= Hash.new
    params[:trip_ticket_filters][:trip_time][:end]   ||= Hash.new
  end
  
  def massage_trip_ticket_trip_time_filter_values_for_form
    if params[:trip_ticket_filters].try(:[], :trip_time).try(:[], :start).try(:[], :hour).present?
      params[:trip_ticket_filters][:trip_time][:start][:hour] = params[:trip_ticket_filters][:trip_time][:start][:hour].to_i
    else
      params[:trip_ticket_filters][:trip_time][:start][:hour] = nil
    end
    if params[:trip_ticket_filters].try(:[], :trip_time).try(:[], :start).try(:[], :minute).present?
      params[:trip_ticket_filters][:trip_time][:start][:minute] = params[:trip_ticket_filters][:trip_time][:start][:minute].to_i
    else
      params[:trip_ticket_filters][:trip_time][:start][:minute] = nil
    end
    if params[:trip_ticket_filters].try(:[], :trip_time).try(:[], :end).try(:[], :hour).present?
      params[:trip_ticket_filters][:trip_time][:end][:hour] = params[:trip_ticket_filters][:trip_time][:end][:hour].to_i
    else
      params[:trip_ticket_filters][:trip_time][:end][:hour] = nil
    end
    if params[:trip_ticket_filters].try(:[], :trip_time).try(:[], :end).try(:[], :minute).present?
      params[:trip_ticket_filters][:trip_time][:end][:minute] = params[:trip_ticket_filters][:trip_time][:end][:minute].to_i
    else
      params[:trip_ticket_filters][:trip_time][:end][:minute] = nil
    end
  end
end
