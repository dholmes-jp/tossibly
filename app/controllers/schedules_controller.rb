class SchedulesController < ApplicationController
  def index
    @schedules = current_user.schedules
    @schedule = current_user.schedules.new(
      scheduled_date: params[:date],
      item_id: params[:item_id]
    )
  end

  def create
    @schedule = current_user.schedules.new(schedule_params)
    if @schedule.save
      redirect_to schedules_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @schedule = current_user.schedules.find(params[:id])

    if @schedule.update(schedule_params)
      redirect_to schedules_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @schedule = current_user.schedules.find(params[:id])
    @schedule.destroy
    redirect_to schedules_path
  end

  private

  def schedule_params
    params.require(:schedule).permit(:title, :scheduled_date, :item_id)
  end
end
