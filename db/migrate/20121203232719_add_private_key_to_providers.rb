class AddPrivateKeyToProviders < ActiveRecord::Migration
  def change
    add_column :providers, :private_key, :string
  end
end
