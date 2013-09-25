class NotificationMailer < ActionMailer::Base
  add_template_helper(ApplicationHelper)
  
  default :from => EMAIL_FROM

  def trip_created(recipients, trip)
    @trip_ticket = trip
    mail(:to => recipients,  :subject => "Ride Connection Clearinghouse: new trip ticket")
  end

  def trip_rescinded(recipients, trip)
    @trip_ticket = trip
    mail(:to => recipients,  :subject => "Ride Connection Clearinghouse: claimed trip ticket rescinded")
  end

  def trip_expired(recipients, trip)
    @trip_ticket = trip
    mail(:to => recipients,  :subject => "Ride Connection Clearinghouse: claimed trip ticket expired")
  end

  def claim_for_approval(recipients, claim)
    @trip_claim = claim
    mail(:to => recipients,  :subject => "Ride Connection Clearinghouse: trip ticket claim awaiting approval")
  end

  def claim_auto_approved(recipients, claim)
    @trip_claim = claim
    mail(:to => recipients,  :subject => "Ride Connection Clearinghouse: trip ticket claim auto-approved")
  end

  def claim_approved(recipients, claim)
    @trip_claim = claim
    mail(:to => recipients,  :subject => "Ride Connection Clearinghouse: trip ticket claim approved")
  end

  def claim_declined(recipients, claim)
    @trip_claim = claim
    mail(:to => recipients,  :subject => "Ride Connection Clearinghouse: trip ticket claim declined")
  end

  def claim_rescinded(recipients, claim)
    @trip_claim = claim
    mail(:to => recipients,  :subject => "Ride Connection Clearinghouse: trip ticket claim rescinded")
  end

  def trip_result_created(recipients, result)
    @trip_result = result
    mail(:to => recipients,  :subject => "Ride Connection Clearinghouse: trip ticket result submitted")
  end

  def trip_comment_created(recipients, comment)
    @trip_comment = comment
    mail(:to => recipients,  :subject => "Ride Connection Clearinghouse: trip ticket comment added")
  end
end
