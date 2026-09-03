class UsersController < ApplicationController
  def dashboard
    # "Continue where you left off" — the 3 most recently touched items.
    @recent_items = current_user.items.order(updated_at: :desc).limit(3)
    # "My scheduled items" — this calendar week's pickups/drop-offs, for the
    # collection strip.
    @weekly_schedules = current_user.schedules
      .where(scheduled_date: Date.current.all_week)
      .order(scheduled_date: :asc)
  end
end
