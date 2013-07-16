class UsersController < ApplicationController
  load_and_authorize_resource

  # GET /users
  # GET /users.json
  def index
    @users = @users.all_by_provider

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @users }
    end
  end

  def logout
    flash[:notice] = 'Logout is not implemented yet.'
    redirect_to root_path
  end

  # My Account (placeholder)
  def account
  end

  # GET /users/1
  # GET /users/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/new
  # GET /users/new.json
  def new
    if !current_user.has_admin_role?
      @user.provider = current_user.provider
    end
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def create    
    # TODO: Factor into model
    if !current_user.has_admin_role?
      @user.provider = current_user.provider
    end
    if params[:user].has_key?(:role_id)
      if Role.provider_roles.exists?(Role.find(params[:user][:role_id]))
        authorize! :set_provider_role, User
      else
        authorize! :set_any_role, User
      end
    end

    respond_to do |format|
      if @user.save
        NewUserMailer.welcome(@user).deliver
        destination = current_user.has_admin_role? ? users_path : provider_path(@user.provider)
        format.html { redirect_to destination, notice: 'User was successfully created.' }
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render action: "new" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.json
  def update
    if params[:user].has_key?(:provider_id)
      authorize! :set_provider, @user
    end
    if params[:user].has_key?(:role_id)
      if Role.provider_roles.exists?(Role.find(params[:user][:role_id]))
        authorize! :set_provider_role, @user
      else
        authorize! :set_any_role, @user
      end
    end
    if params[:user][:password].blank?
      params[:user].delete("password")
      params[:user].delete("password_confirmation")
      need_relogin = false
    elsif @user == current_user
      need_relogin = true
    end

    respond_to do |format|
      if @user.update_attributes(params[:user])
        # Devise logs users out on password change
        sign_in(@user, :bypass => true) if need_relogin
        format.html { redirect_to :back, notice: 'User was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def activate
    params[:user] = { :active => true }
    update
  end

  def deactivate
    params[:user] = { :active => false }
    update
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy

    respond_to do |format|
      format.html { redirect_to users_url }
      format.json { head :no_content }
    end
  end
end
