class NewUserMailer < ActionMailer::Base
  default :from => EMAIL_FROM

  def welcome(user, password = nil, need_to_generate_password = nil)
    @user = user
    @password = user.password || password
    @url = root_url
    @need_to_send_link = user.need_to_generate_password? || need_to_generate_password
    mail(:to => user.email,  :subject => "Welcome to Clearinghouse")
  end
end
