class PagesController < ApplicationController
  skip_before_filter :authenticate_user!
  
  def credits; end
end
