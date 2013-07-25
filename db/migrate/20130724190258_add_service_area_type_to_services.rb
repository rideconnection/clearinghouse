class AddServiceAreaTypeToServices < ActiveRecord::Migration
  def change
    add_column :services, :service_area_type, :string
  end
end
