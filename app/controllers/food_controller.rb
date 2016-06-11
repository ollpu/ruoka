class FoodController < ApplicationController
  def index
    @week = if params[:week_no].present?
      begin
        Week.find_or_create params[:week_no]
      rescue ArgumentError
        head 400 # Better error page, maybe?
      end
    else
      Week.current_or_create
    end
  end
end
