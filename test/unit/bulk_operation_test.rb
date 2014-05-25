require 'test_helper'

class BulkOperationTest < ActiveSupport::TestCase

  it "should require user_id attribute" do
    op = FactoryGirl.build(:bulk_operation, :user => nil)
    op.valid?.must_equal false
    op.errors[:user_id].must_include "can't be blank"
  end

  it "should require data attribute if operation is an upload" do
    op = FactoryGirl.build(:bulk_operation, :is_upload => true, :file_name => nil)
    op.valid?.must_equal false
    op.errors[:file_name].must_include "can't be blank"
  end

  it "should not include the data attribute when converted to JSON" do
    op = FactoryGirl.build(:bulk_operation, :data => "_this_is_data_")
    op.to_json.wont_match /_this_is_data_/
  end
end
