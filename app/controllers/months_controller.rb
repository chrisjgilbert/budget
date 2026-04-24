class MonthsController < ApplicationController
  before_action :load_sidebar

  def index
    if @months.any?
      redirect_to month_path(@months.last)
    end
  end

  def show
    @month = @months.find { |m| m.id == params[:id].to_i } || Month.find(params[:id])
  end

  def create
    month = Month.create_next
    if month
      redirect_to month_path(month)
    else
      redirect_to months_path, alert: "That month already exists."
    end
  end

  private

  def load_sidebar
    @months = Month.chronological.includes(:fields)
  end
end
