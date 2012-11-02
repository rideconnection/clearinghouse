class AddEligibilityToService < ActiveRecord::Migration
  def up
    add_column :services, :eligibility, :hstore
    remove_column :services, :req_min_age
    remove_column :services, :req_veteran
  end

  def down
    remove_column :services, :eligibility
  end
end
