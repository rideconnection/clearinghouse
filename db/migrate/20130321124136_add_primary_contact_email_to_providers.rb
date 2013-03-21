class AddPrimaryContactEmailToProviders < ActiveRecord::Migration
  def change
    add_column :providers, :primary_contact_email, :string
  end
end
