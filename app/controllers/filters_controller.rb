class FiltersController < ApplicationController
  load_and_authorize_resource

  def index
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @filter }
    end
  end

  def new
    respond_to do |format|
      format.html
      format.json { render json: @filter }
    end
  end

  def create
    @filter = current_user.filters.build(params[:filter])

    respond_to do |format|
      if @filter.save
        format.html do
          if params[:return_to] == 'trip_tickets'
            redirect_to trip_tickets_url(saved_filter: @filter.name), notice: 'Filter was successfully created.'
          else
            redirect_to @filter, notice: 'Filter was successfully created.'
          end
        end
        format.json { render json: @filter, status: :created, location: @filter }
      else
        format.html do
          if params[:return_to] == 'trip_tickets'
            redirect_to :back, alert: "Error creating filter. #{@filter.errors.full_messages.first}."
          else
            render action: "new"
          end
        end
        format.json { render json: @filter.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @filter.update_attributes(params[:filter])
        format.html do
          if params[:return_to] == 'trip_tickets'
            redirect_to apply_filters_trip_tickets_url(saved_filter: @filter.name), notice: 'Filter was successfully updated.'
          else
            redirect_to @filter, notice: 'Filter was successfully updated.'
          end
        end
        format.json { head :no_content }
      else
        format.html do
          if params[:return_to] == 'trip_tickets'
            redirect_to :back, alert: "Error creating filter. #{@filter.errors.full_messages.first}."
          else
            render action: "edit"
          end
        end
        format.json { render json: @filter.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @filter.destroy

    respond_to do |format|
      format.html do
        if params[:return_to] == 'trip_tickets'
          redirect_to clear_filters_trip_tickets_url, notice: 'Filter was successfully deleted.'
        else
          redirect_to filters_url
        end
      end
      format.json { head :no_content }
    end
  end
end
