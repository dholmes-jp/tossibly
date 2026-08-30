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
    # Defaults to "listable" if the form doesn't send a value.
    # Logic is that it's safer to show Jimoty than to possibly hide it for an item.
    listable = item_params[:listable].nil? || ActiveModel::Type::Boolean.new.cast(item_params[:listable])

    if listable
      generated = ItemDescriber.new(identification, answers, item_params[:photos]).call || {}

      # ayaka added / start
      jimoty_categories = JimotyCategorySelector.new.call(
        {
          identification: identification,
          answers: answers,
          listing: generated
        }
      ) || {}
      # ayaka added / end

      generated = generated.merge(platform: "jimoty")
    else
      # Non-listable items never get Jimoty listing copy generated at all — not just hidden.
      # Built from what identify already determined; no extra AI call, and guarantees `title`
      # presence since identification[:name] never reaches the server.
      plain_title = [identification[:brand],
                     identification[:category]].compact_blank.join(" ").presence || "Unlisted item"
      generated = { title: plain_title, description: "Not offered on Jimoty — routed straight to disposal." }
      jimoty_categories = {}
    end

    @item = current_user.items.new(item_params.except(:follow_up_answers, :follow_up_question_texts,
                                                      :condition_guess, :listable)
                                                      .merge(generated.slice(*Item.column_names.map(&:to_sym)))
                                                      .merge(jimoty_category_value: jimoty_categories[:category_value], jimoty_large_genre_value: jimoty_categories[:large_genre_value], jimoty_medium_genre_value: jimoty_categories[:medium_genre_value], listable: listable))
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
      :brand, :model_number, :suggested_price, :confirmed_price, :disposal_fee, :jimoty_category,
      :condition_guess, :waste_category_key, :listable,
      photos: [], follow_up_answers: [], follow_up_question_texts: []
    )
  end

  def build_answers(params)
    questions = Array(params[:follow_up_question_texts])
    responses = Array(params[:follow_up_answers])
    questions.zip(responses).to_h
  end
end
