class ItemsController < ApplicationController
  before_action :set_item, only: %i[show update destroy]

  def index
    @items = current_user.items.order(created_at: :desc)
    @items = @items.where(status: params[:status]) if params[:status].present?
    @platform = params[:platform].presence || "other"
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
    photos = Array(item_params[:photos]).reject(&:blank?)
    answers = build_answers(item_params).merge(condition: params[:condition], note: params[:note])
    identification = item_params.slice(:brand, :category, :model_number, :condition_guess)
    # Defaults to "listable" if the form doesn't send a value.
    # Logic is that it's safer to show Jimoty than to possibly hide it for an item.
    listable = item_params[:listable].nil? || ActiveModel::Type::Boolean.new.cast(item_params[:listable])

    if listable
      generated = ItemDescriber.new(identification, answers, photos).call || {}

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
    identification = item_params.slice(:brand, :category, :model_number, :condition_guess).to_h
    answers = build_answers(item_params).merge("condition" => params[:condition], "note" => params[:note])
    # Defaults to "listable" if the form doesn't send a value.
    # Logic is that it's safer to show Jimoty than to possibly hide it for an item.
    listable = item_params[:listable].nil? || ActiveModel::Type::Boolean.new.cast(item_params[:listable])
    # identification[:name] never reaches the server, so this guarantees the presence
    # validation passes. For listable items ProcessItemJob overwrites it moments later.
    name_parts = [identification["brand"], identification["category"]]
    provisional_title = name_parts.compact_blank.join(" ").presence || "Unlisted item"

    attrs = { title: provisional_title, listable: listable }

    unless listable
      # Non-listable items never get Jimoty listing copy or a nearby-listing search — the job
      # would be a no-op for them beyond processed_at, so skip it and finish the record now.
      attrs = attrs.merge(
        description: "Not offered on Jimoty — routed straight to disposal.",
        processed_at: Time.current
      )
    end

    @item = current_user.items.new(item_params.except(:follow_up_answers, :follow_up_question_texts,
                                                      :condition_guess, :listable)
                                                .merge(attrs))

    if @item.save
      ProcessItemJob.perform_later(@item, identification: identification, answers: answers) if listable
      redirect_to @item, notice: "Item created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    # if @item.update(item_params)
    #   redirect_to @item, notice: "Item updated."
    # else
    #   render :show, status: :unprocessable_entity
    # end
    # note: changed for "status" in index page
    if @item.update(item_params)
      redirect_back fallback_location: items_path, notice: "Item updated."
    else
      redirect_back fallback_location: items_path, alert: "Update failed."
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
      :condition_guess, :waste_category_key, :listable, :jimoty_search_keyword, :status,
      photos: [], follow_up_answers: [], follow_up_question_texts: []
    )
  end

  def build_answers(params)
    questions = Array(params[:follow_up_question_texts])
    responses = Array(params[:follow_up_answers])
    questions.zip(responses).to_h
  end
end
