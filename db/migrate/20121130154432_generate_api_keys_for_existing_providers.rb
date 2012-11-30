class GenerateApiKeysForExistingProviders < ActiveRecord::Migration
  def up
    transaction do
      Provider.all.each do |provider|
        provider.generate_api_key! unless provider.api_key.present?
      end
    end
  end

  def down
  end
end
