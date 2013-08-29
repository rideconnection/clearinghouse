class BulkOperation < ActiveRecord::Base
  belongs_to :user

  attr_accessible :row_count, :last_import_time, :is_upload, :file_name, :error_count, :bad_row_numbers, :data

  validates_presence_of :user_id

  SINGLE_DOWNLOAD_LIMIT = 200

  def to_json(options = {})
    attributes.delete_if {|k| k.to_s == 'data'}.merge({ data: data.present? }).to_json(options)
  end

  def self.make_file_name
    "ride_clearinghouse_download-#{Time.zone.now.strftime("%Y%m%d-%H%M%S")}.csv"
  end
end
