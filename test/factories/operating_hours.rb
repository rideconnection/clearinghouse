# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :operating_hours do
    day_of_week 0
    open_time "00:00:00"
    close_time "23:59:59"
    service
  end
end
