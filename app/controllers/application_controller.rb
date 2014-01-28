class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :apply_application_settings
  before_filter :authenticate_user!
  
  # TODO - Should we allow normal caching for any requests? If so, move this 
  # into individual controllers and use the :only/:except parameters to limit
  # what actions are affected
  before_filter :set_cache_buster

  rescue_from CanCan::AccessDenied do |exception|
    error_message = exception.message.gsub(/\bthis\b/, "that")
    respond_to do |format|
      format.html { redirect_to root_url, :alert => error_message }
      format.json { render json: {errors: {base: [error_message]}}, status: :unprocessable_entity }
    end
  end
  
  private
  
  def apply_application_settings
    ApplicationSetting.apply!
  end
  
  def set_cache_buster
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end
  
  def admins_only
    raise CanCan::AccessDenied unless current_user && current_user.has_any_role?([:site_admin, :provider_admin])
  end

  # for use with time_select form helper - if time is left blank, make sure corresponding params and attribute get set to nil
  # can handle nested attributes but only for 1-to-1 associations

  def allow_blank_time_field(object, param_name, nested_within = nil)
    param_hash = nested_within.present? ? params[nested_within] : params
    return if param_hash.blank?

    object_type = object.class.name.underscore
    object_key = nested_within.present? ? "#{object_type}_attributes" : object_type
    object_hash = param_hash[object_key]

    if object_hash.present? && object_hash["#{param_name}(4i)"].blank? && object_hash["#{param_name}(5i)"].blank?
      param_name_list = ["(1i)", "(2i)", "(3i)", "(4i)", "(5i)"].map {|x| "#{param_name}#{x}" }
      param_name_list.each do |param|
        if nested_within.present?
          params[nested_within][object_key].delete(param)
        else
          params[object_key].delete(param)
        end
      end
      if nested_within.present?
        params[nested_within][object_key][param_name] = nil
      else
        params[object_key][param_name] = nil
      end
      object.send("#{param_name}=", nil) if object
    end
  end

  def render_with_format(hash)
    format = hash.delete(:format)
    logger.debug format
    original_format = @template_format
    @template_format = format
    begin
      render(hash)
    ensure
      @template_format = original_format
    end
  end
end
