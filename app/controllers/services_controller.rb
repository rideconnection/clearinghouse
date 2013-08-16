class ServicesController < ApplicationController
  load_and_authorize_resource

  def new
    prepare_form
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @service }
    end
  end

  def edit
    prepare_form
  end

  def create
    respond_to do |format|
      begin
        @service.provider = Provider.find(params[:provider_id])
        update_polygon
        Service.transaction do
          @service.save!
          create_or_update_hours
        end
        format.html { redirect_to provider_path(@service.provider), notice: 'Service was successfully created.' }
        format.json { render json: @service, status: :created, location: @service }
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.debug e.message
        prepare_form
        format.html { render action: "new" }
        format.json { render json: @service.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      begin
        update_polygon
        Service.transaction do
          @service.update_attributes params[:service]
          create_or_update_hours
        end
        format.html { redirect_to provider_path(@service.provider), notice: 'Service was successfully updated.' }
        format.json { head :no_content }
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.debug e.message
        prepare_form
        format.html { render action: "edit" }
        format.json { render json: @service.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def create_or_update_hours
    hours = @service.hours_hash
    if !hours.empty?  and hours.length < 7
      hours.each_pair { |day, h| h.destroy }
      hours = {}
    end
    if hours.empty?
      (0..6).each do |d|
        hours[d] = OperatingHours.new :day_of_week => d, :service => @service
      end
    end
    errors = false
    params[:hours].each_pair do |day, value|
      begin
        day = day.to_i
        day_hours = hours[day]
        if day_hours.nil?
          day_hours = OperatingHours.new :day_of_week => day, :service => @service
        end
        case value
          when 'closed'
            day_hours.make_closed!
          when 'open24'
            day_hours.make_24_hours!
          when 'open'
            day_hours.open_time = params[:start_hour][day.to_s]
            day_hours.close_time = params[:end_hour][day.to_s]
          else
            @service.errors.add :operating_hours,
                                'must be "closed", "open24", or "open".'
            raise ActiveRecord::RecordInvalid.new(@service)
        end
        day_hours.save!
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.debug e.message
        errors = true
      end
    end
    if errors
      raise ActiveRecord::RecordInvalid.new(@service)
    end
  end

  def prepare_form
    @service.provider = Provider.find(params[:provider_id])
    @hours = @service.hours_hash
    @start_hours = []
    @end_hours = []
    interval = 30.minutes
    
    # We only need the time as a string, but we'll use some temporary Time
    # objects to help us do some simple time math. The dates returned are
    # irrelevant
    t1 = OperatingHours::START_OF_DAY
    t2 = Time.zone.parse('00:00:00')
    t  = Time.zone.parse(t1)
    
    puts "#{t}"
    puts "#{t2}"
    while t.to_s(:time_utc) != t2.to_s(:time_utc) do
      @start_hours << t
      t += interval
      puts "#{t}"
    end
    
    t = Time.parse(t1) + interval
    while true do
      @end_hours << t
      break if t.to_s(:time_utc) == OperatingHours::END_OF_DAY
      t += interval
    end
  end

  def update_polygon
    points = []
    if !params[:service_area].nil?
      params[:service_area].each_pair do |key, value|
        points << "#{value[:lng]} #{value[:lat]}"
      end
    end
    wkt = nil
    if points.any?
      wkt = "POLYGON ((#{points.join(", ")}))"
    end
    @service.service_area = wkt
  end
end
