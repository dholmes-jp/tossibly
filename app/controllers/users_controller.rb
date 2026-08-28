class UsersController < ApplicationController
  def dashboard
    # "Continue where you left off" — the 3 most recently touched items.
    @recent_items = current_user.items.order(updated_at: :desc).limit(3)
  end
end
