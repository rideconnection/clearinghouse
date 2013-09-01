require 'trip_ticket_export'
require 'trip_ticket_import'

class BulkOperationsController < ApplicationController
  load_and_authorize_resource
  skip_load_resource :only => [ :index, :create ]

  def index
    @bulk_operations = BulkOperation.accessible_by(current_ability).order('created_at DESC').page(params[:page]).per(5)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @bulk_operations }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @bulk_operation }
    end
  end

  def new
    @bulk_operation.is_upload = params[:operation_type].try(:to_sym) == :upload

    unless @bulk_operation.is_upload?
      @last_download = BulkOperation.maximum(:created_at)
      @last_update = BulkOperation.maximum(:last_exported_timestamp)
      @row_count = if @last_update.blank?
        TripTicket.accessible_by(current_ability).count
      else
        TripTicket.accessible_by(current_ability).where('updated_at > ?', @last_update).count
      end
    end

    respond_to do |format|
      format.html
      format.json { render json: @bulk_operation }
    end
  end

  def create
    uploaded_file = params[:bulk_operation].try(:delete, :uploaded_file)
    @bulk_operation = current_user.bulk_operations.build(params[:bulk_operation])
    save_upload(uploaded_file) if @bulk_operation.is_upload?

    respond_to do |format|
      if @bulk_operation.save
        format.html do
          if @bulk_operation.is_upload?
            if Rails.env.development?
              self.class.import(current_user.id, @bulk_operation.id)
            else
              self.class.delay.import(current_user.id, @bulk_operation.id)
            end
            redirect_to bulk_operation_url(@bulk_operation)
          else
            if Rails.env.development?
              self.class.export(current_user.id, @bulk_operation.id)
            else
              self.class.delay.export(current_user.id, @bulk_operation.id)
            end
            redirect_to bulk_operation_url(@bulk_operation, :download => true)
          end
        end
        format.json { render json: @bulk_operation }
      else
        format.html { render action: "new" }
        format.json { render json: @bulk_operation.errors, status: :unprocessable_entity }
      end
    end
  end

  def download
    send_data(@bulk_operation.data, type: 'text/csv', disposition: 'attachment', filename: @bulk_operation.file_name)
  end

  def self.export(user_id, bulk_operation_id)
    user = User.find(user_id)
    bulk_operation = BulkOperation.find(bulk_operation_id)
    last_update = user.bulk_operations.maximum(:last_exported_timestamp)
    trip_filter = ['updated_at > ?', last_update] if last_update.present?
    exporter = TripTicketExport.new(BulkOperation::SINGLE_DOWNLOAD_LIMIT)
    exporter.process(TripTicket.accessible_by(::Ability.new(user)).where(trip_filter))
    bulk_operation.completed = true
    bulk_operation.data = exporter.data
    bulk_operation.row_count = exporter.row_count
    bulk_operation.last_exported_timestamp = exporter.last_exported_timestamp
    bulk_operation.file_name = BulkOperation.make_file_name
    bulk_operation.save!
  end

  def self.import(user_id, bulk_operation_id)
    user = User.find(user_id)
    bulk_operation = BulkOperation.find(bulk_operation_id)
    importer = TripTicketImport.new(user.provider)
    begin
      importer.process(bulk_operation.data)
    rescue
      logger.error "Import exception #{$!}"
    ensure
      bulk_operation.completed = true
      bulk_operation.row_count = importer.row_count
      bulk_operation.error_count = importer.errors.length
      bulk_operation.row_errors = importer.errors
      bulk_operation.save!
    end
  end

  protected

  def save_upload(uploaded_file)
    if uploaded_file.present?
      logger.debug "Saving contents of uploaded file for bulk operation processing: #{uploaded_file}, #{uploaded_file.class}, IO? #{uploaded_file.is_a?(IO)}"
      @bulk_operation.data = uploaded_file.read
      @bulk_operation.file_name = uploaded_file.original_filename
      logger.debug "Uploaded file name: #{@bulk_operation.file_name}, data: #{@bulk_operation.data}"
    else
      logger.debug "Uploaded file for bulk operation processing is empty"
    end
  end
end
