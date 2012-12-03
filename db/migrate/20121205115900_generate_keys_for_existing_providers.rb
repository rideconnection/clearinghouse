class GenerateKeysForExistingProviders < ActiveRecord::Migration
  def up
    transaction do
      Provider.all.each do |provider|
        provider.regenerate_keys!(false)
      end
    end
  end

  def down
  end
end
