class ConvertTripClaimStatusIndicatorToString < ActiveRecord::Migration
  
  class TripClaim < ActiveRecord::Base
    STATUS = {
      :pending   => 0,
      :approved  => 1,
      :declined  => -1,
      :rescinded => -2
    }
    
    STATUS_INVERTED = {
      0  => :pending,
      1  => :approved,
      -1 => :declined,
      -2 => :rescinded
    }
    
    attr_accessible :status, :new_status
  end
  
  def up
    transaction do
      add_column :trip_claims, :new_status, :string
    
      TripClaim.all.each do |claim|
        if claim.status.blank? || TripClaim::STATUS_INVERTED[claim.status].blank?
          claim.new_status = :pending
        else
          claim.new_status = TripClaim::STATUS_INVERTED[claim.status]
        end
        claim.save!
      end
    
      remove_column :trip_claims, :status
      rename_column :trip_claims, :new_status, :status
      add_index :trip_claims, :status
    end
  end

  def down
    add_column :trip_claims, :new_status, :integer
  
    TripClaim.all.each do |claim|
      if claim.status.blank? || TripClaim::STATUS[claim.status.to_sym].blank?
        claim.new_status = TripClaim::STATUS[:pending]
      else
        claim.new_status = TripClaim::STATUS[claim.status.to_sym]
      end
      claim.save!
    end
  
    remove_column :trip_claims, :status
    rename_column :trip_claims, :new_status, :status
    add_index :trip_claims, :status
  end
end