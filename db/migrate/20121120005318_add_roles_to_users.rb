class AddRolesToUsers < ActiveRecord::Migration
  def self.up
    create_table :roles do |t|
      t.string :name
    end
    create_table :roles_users, :id => false do |t|
      t.references :role, :user
    end
  end
 
  def self.down
    drop_table :roles_users
    drop_table :roles
  end
end
