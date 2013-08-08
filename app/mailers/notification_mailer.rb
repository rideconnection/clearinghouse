class NotificationMailer < ActionMailer::Base
  default :from => EMAIL_FROM

  def test_notification(recipients, model)
    @model = model
    mail(:to => recipients,  :subject => "Test Notification from Ride Clearinghouse")
  end

end
