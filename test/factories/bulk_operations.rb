# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :bulk_operation do
    association :user
    is_upload false
    file_name 'test.csv'
    data 'dummy'
  end
end
