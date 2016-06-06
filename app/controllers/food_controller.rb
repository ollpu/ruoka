class FoodController < ApplicationController
  def index
    @week = if params[:week_no].present?
      Week.find_by_week_no params[:week_no]
      # todo: record not found
    else
      Week.current
    end
  end
end
