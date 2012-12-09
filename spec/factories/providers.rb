# Read about factories at https://github.com/thoughtbot/factory_girl

# Creates a user to serve as primary contact. Pass a User as :primary_contact
# to use that instead of creating a new user.
FactoryGirl.define do
  factory :provider do
    ignore do
      primary_contact nil
    end
    name "My Provider"
    address { FactoryGirl.create(:location) }
    after :build do |provider, evaluator|
      if evaluator.primary_contact.nil?
        provider.primary_contact = FactoryGirl.create(:user,:provider=>provider)
      else
        provider.primary_contact = evaluator.primary_contact
      end
    end
  end
end
