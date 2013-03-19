class UpdateRolesTable < ActiveRecord::Migration

  class User < ActiveRecord::Base
    belongs_to :role, :class_name => 'UpdateRolesTable::Role'
    attr_accessible :role
  end

  class Role < ActiveRecord::Base
    has_many :users, :class_name => 'UpdateRolesTable::User'
  end

  def up
    transaction do
      read_only = Role.find_or_create_by_name(:read_only)
    
      Role.find_or_initialize_by_name(:csr).users.try(:each) do |user|
        user.role = read_only
        user.save!
      end
    
      Role.find_or_initialize_by_name(:csr).destroy
    end
  end

  def down
    transaction do
      csr = Role.find_or_create_by_name(:csr)
    
      Role.find_or_initialize_by_name(:read_only).users.try(:each) do |user|
        user.role = csr
        user.save!
      end
    
      Role.find_or_initialize_by_name(:read_only).destroy
    end
  end
end
