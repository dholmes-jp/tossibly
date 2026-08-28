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

  def identify
    @identification = ItemIdentifier.new(photos).call

    locals = { identification: @identification }

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("identification", partial: "items/identification", locals: locals),
          turbo_stream.replace("follow_up_questions", partial: "items/follow_up_questions", locals: locals)
        ]
      end
    end
  end

  def create
    answers = build_answers(item_params).merge(condition: params[:condition], note: params[:note])
    identification = item_params.slice(:brand, :category, :model_number, :condition_guess)
    generated = ItemDescriber.new(identification, answers, item_params[:photos]).call || {}

    @item = current_user.items.new(item_params.except(:follow_up_answers, :follow_up_question_texts,
                                                      :condition_guess).merge(generated.slice(*Item.column_names.map(&:to_sym))))
    # @item.photos.attach(item_params[:photos]) if item_params[:photos]

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

  def photos
    params[:photos]
  end

  def item_params
    params.require(:item).permit(
      :title, :category, :platform, :description, :description_ja, :title_ja, :age, :functional,
      :brand, :model_number, :suggested_price, :disposal_fee, :jimoty_category, :condition_guess,
      photos: [], follow_up_answers: [], follow_up_question_texts: []
    )
  end

  def build_answers(params)
    questions = Array(params[:follow_up_question_texts])
    responses = Array(params[:follow_up_answers])
    questions.zip(responses).to_h
  end
end
