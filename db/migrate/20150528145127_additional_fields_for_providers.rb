class AdditionalFieldsForProviders < ActiveRecord::Migration
  def change
    add_column :locations, :address_type, :string   # description of type (church, office, etc.)
  end
end
