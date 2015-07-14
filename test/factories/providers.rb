# Read about factories at https://github.com/thoughtbot/factory_girl

# Creates a user to serve as primary contact.
FactoryGirl.define do
  factory :provider do
    name "My Provider"
    address { FactoryGirl.create(:location) }
    primary_contact_email "some@nights.fun"
  end
end
