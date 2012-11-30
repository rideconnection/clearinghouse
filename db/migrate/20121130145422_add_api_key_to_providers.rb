class AddApiKeyToProviders < ActiveRecord::Migration
  def change
    add_column :providers, :api_key, :string
    add_index :providers, :api_key, :unique => true
  end
end