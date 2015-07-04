class OpenCapacitiesController < ApplicationController

  def index
  end

  def show
  end

  def edit
  end

  private

  def open_capacity_params
    params.require(:open_capacity).permit(:arrival_location_id, :arrival_time, :departure_location_id,
      :departure_time, :notes, :scooter_spaces_open, :seats_open, :wheelchair_spaces_open, :service_id)
  end
end
