class BulkOperation < ActiveRecord::Base
  belongs_to :user

  attr_accessible :row_count, :last_exported_timestamp, :is_upload, :file_name, :error_count, :row_errors, :data

  validates_presence_of :user_id
  validates_presence_of :file_name, on: :create, if: Proc.new { |op| op.is_upload? }
  validates_presence_of :data, on: :create, if: Proc.new { |op| op.is_upload? && op.file_name.present? }

  SINGLE_DOWNLOAD_LIMIT = 200

  def to_json(options = {})
    attributes.delete_if {|k| k.to_s == 'data'}.merge({ data: data.present? }).to_json(options)
  end

  def self.make_file_name
    "clearinghouse_download_#{Time.zone.now.strftime("%Y%m%d_%H%M%S")}.csv"
  end
end
