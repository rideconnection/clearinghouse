# Implement http://bit.ly/18D7fDa (How To: Override confirmations so users can
# pick their own passwords as part of confirmation activation)

class ConfirmationsController < Devise::ConfirmationsController
  # Remove the first skip_before_filter (:require_no_authentication) if you
  # don't want to enable logged users to access the confirmation page.
  skip_before_filter :require_no_authentication
  skip_before_filter :authenticate_user!

  # PUT /resource/confirmation
  def update
    with_unconfirmed_confirmable do
      if resource.has_no_password?
        resource.attempt_set_password(params[:user])
        if resource.valid?
          do_confirm
        else
          do_show
          resource.errors.clear # so that we wont render :new
        end
      else
        resource.errors.add(:base, "Your password has already been set")
      end
    end

    if !resource.errors.empty?
      render 'devise/confirmations/new'
    end
  end

  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    with_unconfirmed_confirmable do
      if resource.has_no_password?
        do_show
      else
        do_confirm
      end
    end
    
    if !resource.errors.empty?
      render 'devise/confirmations/new'
    end
  end

  protected

  def with_unconfirmed_confirmable
    original_token = params[:confirmation_token]
    confirmation_token = Devise.token_generator.digest(User, :confirmation_token, original_token)
    self.resource = User.find_or_initialize_with_error_by(:confirmation_token, confirmation_token)
    if !resource.new_record?
      resource.only_if_unconfirmed {yield}
    end
  end

  def do_show
    @confirmation_token = params[:confirmation_token]
    @requires_password = true
    # Change this if you don't have the views on default path
    render 'devise/confirmations/show'
  end

  def do_confirm
    resource.confirm!
    set_flash_message :notice, :confirmed
    sign_in_and_redirect(resource_name, resource)
  end
end
