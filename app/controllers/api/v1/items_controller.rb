class Api::V1::ItemsController < ApplicationController
  def index
    @items = current_user.items
    render json: @items
  end

  def show
    # @item = Item.find(params[:id])
    @item = current_user.items.find(params[:id])
    # Putting the most recently created items first
    render json: @item.as_json.merge(photo_urls: @item.photo_urls)
  end
end
