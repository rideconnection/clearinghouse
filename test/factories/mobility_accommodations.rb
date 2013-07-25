# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :mobility_accommodation do
    service
    mobility_impairment 'Wheelchair'
  end
end
