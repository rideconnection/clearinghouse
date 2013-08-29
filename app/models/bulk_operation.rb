class BulkOperation < ActiveRecord::Base
  belongs_to :user

  attr_accessible :row_count, :last_import_time, :is_upload, :file_name, :error_count, :bad_row_numbers, :data

  validates_presence_of :user_id

  SINGLE_DOWNLOAD_LIMIT = 200

  def self.make_file_name
    "ride_clearinghouse_download-#{Time.zone.now.strftime("%Y%m%d-%H%M%S")}.csv"
  end
end