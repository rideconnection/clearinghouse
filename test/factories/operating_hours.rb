# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :operating_hours do
    day_of_week 0
    open_time Time.parse("00:00:00 UTC")
    close_time Time.parse("23:59:59 UTC")
    service
  end
end
