class UpdateRolesTable < ActiveRecord::Migration

  def up
    transaction do
      read_only = Role.find_or_create_by(name: :read_only)
    
      Role.find_or_initialize_by(name: :csr).users.try(:each) do |user|
        user.role = read_only
        user.save!
      end
    
      Role.find_or_initialize_by(name: :csr).destroy
    end
  end

  def down
    transaction do
      csr = Role.find_or_create_by(name: :csr)
    
      Role.find_or_initialize_by(name: :read_only).users.try(:each) do |user|
        user.role = csr
        user.save!
      end
    
      Role.find_or_initialize_by(name: :read_only).destroy
    end
  end
end
