class UsersController < ApplicationController
  def dashboard
    # "Continue where you left off" — the most recently touched items.
    # No status column exists yet, so this is recency-only, capped at 3.
    @items = current_user.items.order(updated_at: :desc).limit(3).to_a
  end
end
