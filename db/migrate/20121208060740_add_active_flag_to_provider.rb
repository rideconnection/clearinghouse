class AddActiveFlagToProvider < ActiveRecord::Migration
  def change
    change_table :providers do |t|
      t.boolean :active
    end
  end
end
