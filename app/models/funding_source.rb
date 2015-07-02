class FundingSource < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  #attr_accessible :name
end
