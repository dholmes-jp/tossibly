class ItemsController < ApplicationController
  before_action :set_item, only: %i[show edit update destroy]

  def index
    @items = current_user.items.order(created_at: :desc)
    @items = @items.where(status: params[:status]) if params[:status].present?
    @items = @items.where(platform: params[:platform]) if params[:platform].present?
  end

  def show
  end

  def new
    @item = current_user.items.new
  end

  def create
    @item = current_user.items.new(item_params)
    if @item.save
      redirect_to @item, notice: "Item created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @item.update(item_params)
      redirect_to @item, notice: "Item updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @item.destroy
    redirect_to items_path, notice: "Item deleted."
  end

  private

  def set_item
    @item = current_user.items.find(params[:id])
  end

  def item_params
    params.require(:item).permit(
      :title, :category, :platform, :description, :description_ja, :title_ja, :age, :functional, :brand, :model_number, :suggested_price, :disposal_fee, :jimoty_category, photos: []
    )
  end
end
