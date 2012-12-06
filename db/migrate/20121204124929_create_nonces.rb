class CreateNonces < ActiveRecord::Migration
  def change
    create_table :nonces do |t|
      t.string :nonce
      t.integer :provider_id

      t.timestamps
    end
    
    add_index :nonces, [:nonce, :provider_id], :unique => true
  end
end