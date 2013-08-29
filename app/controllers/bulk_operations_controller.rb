require 'trip_ticket_export'

class BulkOperationsController < ApplicationController
  load_and_authorize_resource
  skip_load_resource :only => :index

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
      @last_update = BulkOperation.maximum(:last_import_time)
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
    @bulk_operation = current_user.bulk_operations.build(params[:bulk_operation])

    # TODO use DJ for this to do it in the background

    if @bulk_operation.is_upload?
      # TODO for upload, we should be accepting a file upload in the form, then import and process the data
    else
      last_update = current_user.bulk_operations.maximum(:last_import_time)
      trip_filter = ['updated_at > ?', last_update] if last_update.present?
      exporter = TripTicketExport.new(BulkOperation::SINGLE_DOWNLOAD_LIMIT)
      exporter.process(TripTicket.accessible_by(current_ability).where(trip_filter))
      @bulk_operation.data = exporter.data
      @bulk_operation.row_count = exporter.row_count
      @bulk_operation.last_import_time = exporter.last_import_time
      @bulk_operation.file_name = BulkOperation.make_file_name
    end

    respond_to do |format|
      if @bulk_operation.save
        format.html { redirect_to bulk_operation_url(@bulk_operation, :download => true) }
        format.json { render json: @bulk_operation }
      else
        format.html { render action: "new" }
        format.json { render json: @bulk_operation.errors, status: :unprocessable_entity }
      end
    end
  end

  def download
    send_download(@bulk_operation)
  end

  protected

  def send_download(bulk_operation)
    send_data(bulk_operation.data, type: 'text/csv', disposition: 'attachment', filename: bulk_operation.file_name)
  end
end
