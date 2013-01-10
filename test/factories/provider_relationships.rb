# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :provider_relationship do
    requesting_provider_id 1
    cooperating_provider_id 1
    approved_at "2013-01-07"
    automatic_requester_approval false
    automatic_cooperator_approval false
  end
end
