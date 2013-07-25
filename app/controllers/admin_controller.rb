class AdminController < ApplicationController
  before_filter :admins_only

  def index; end
end
