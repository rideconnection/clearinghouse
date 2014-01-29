class ApplicationSettingsController < ApplicationController
  before_filter :admins_only
  
  def index
  end

  def edit
    @settings = ApplicationSetting.unscoped
  end

  def update
    respond_to do |format|
      if ApplicationSetting.update_settings params[:application_setting]
        format.html { redirect_to application_settings_path, notice: 'Application settings were successfully updated.' }
        format.json { head :no_content }
      else
        @settings = ApplicationSetting.unscoped.merge params[:application_setting]
        format.html { render action: :edit }
        format.json { render json: ApplicationSetting.all, status: :unprocessable_entity }
      end
    end
  end
end
