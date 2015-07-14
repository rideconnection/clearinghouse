class RemoveActiveFromProviders < ActiveRecord::Migration
  def change
    remove_column :providers, :active, :boolean, default: true, null: false
  end
end
