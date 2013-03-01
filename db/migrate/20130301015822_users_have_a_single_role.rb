class UsersHaveASingleRole < ActiveRecord::Migration

  class User < ActiveRecord::Base
    has_and_belongs_to_many :roles
    attr_accessible :role_id
  end

  def up
    transaction do
      add_column :users, :role_id, :integer
      
      User.reset_column_information
      
      User.all.each do |user|
        user.role_id = user.roles.first.id unless user.roles.empty?
        user.save!
      end
    
      drop_table :roles_users
    end
  end

  def down
    transaction do
      create_table :roles_users, :id => false do |t|
        t.references :role, :user
      end

      add_index :roles_users, [:role_id, :user_id], :unique => true
      add_index :roles_users, :role_id
      add_index :roles_users, :user_id
    
      User.reset_column_information
    
      User.all.each do |user|
        user.roles << Role.find(user.role_id) unless user.role_id.blank?
      end
    
      remove_column :users, :role_id
    end
  end
end
