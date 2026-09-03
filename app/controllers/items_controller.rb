class ItemsController < ApplicationController
  before_action :set_item, only: %i[show update destroy]

  # See #save_item_with_retry below.
  RETRYABLE_UPLOAD_ERRORS = [Faraday::TimeoutError, Faraday::ConnectionFailed,
                             Net::ReadTimeout, Net::OpenTimeout].freeze
  MAX_SAVE_ATTEMPTS = 3

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

    # Non-listable items now get a real disposal card straight away — free or
    # fee-tiered alike — so branch on listability alone. A never-saved preview
    # Item is enough for DisposalFeeEstimator, which only reads accessors.
    preview_item = Item.new(
      waste_category_key: @identification[:waste_category_key],
      title: provisional_title(@identification),
      category: @identification[:category]
    )
    locals = { identification: @identification, dispose: DisposalPanelPresenter.call(preview_item) }

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("identification", partial: "items/identification", locals: locals),
          turbo_stream.replace(
            "follow_up_questions",
            partial: @identification[:listable] ? "items/reuse_prompt_result" : "items/single_path_result",
            locals: locals
          )
        ]
      end
    end
  end

  def create
    # photos = Array(item_params[:photos]).reject(&:blank?)
    # answers = build_answers(item_params).merge(condition: params[:condition], note: params[:note])
    # identification = item_params.slice(:brand, :category, :model_number, :condition_guess)
    # # Defaults to "listable" if the form doesn't send a value.
    # # Logic is that it's safer to show Jimoty than to possibly hide it for an item.
    # listable = item_params[:listable].nil? || ActiveModel::Type::Boolean.new.cast(item_params[:listable])

    # if listable
    #   generated = ItemDescriber.new(identification, answers, photos).call || {}

    #   # ayaka added / start
    #   jimoty_categories = JimotyCategorySelector.new.call(
    #     {
    #       identification: identification,
    #       answers: answers,
    #       listing: generated
    #     }
    #   ) || {}
    #   # ayaka added / end

    #   generated = generated.merge(platform: "jimoty")
    # else
    #   # Non-listable items never get Jimoty listing copy generated at all — not just hidden.
    #   # Built from what identify already determined; no extra AI call, and guarantees `title`
    #   # presence since identification[:name] never reaches the server.
    #   plain_title = [identification[:brand],
    #                  identification[:category]].compact_blank.join(" ").presence || "Unlisted item"
    #   generated = { title: plain_title, description: "Not offered on Jimoty — routed straight to disposal." }
    #   jimoty_categories = {}

    identification = item_params.slice(:brand, :category, :model_number, :condition_guess).to_h
    answers = build_answers(item_params).merge("condition" => params[:condition], "note" => params[:note])
    # Defaults to "listable" if the form doesn't send a value.
    # Logic is that it's safer to show Jimoty than to possibly hide it for an item.
    listable = item_params[:listable].nil? || ActiveModel::Type::Boolean.new.cast(item_params[:listable])
    # identification[:name] never reaches the server, so this guarantees the presence
    # validation passes. For listable items ProcessItemJob overwrites it moments later.
    attrs = { title: provisional_title(identification), listable: listable }

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

    if save_item_with_retry(@item)
      ProcessItemJob.perform_later(@item, identification: identification, answers: answers) if listable

      # The single-path skip case ("Set Reminder" on _single_path_result) saves a
      # throwaway, non-listable item purely so it can be attached to a calendar
      # reminder, instead of the normal "saved to My Items" success screen.
      return handle_set_reminder(@item) if params[:set_reminder] == "1"

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "follow_up_questions", partial: "items/save_success", locals: { item: @item }
          )
        end
        # Fallback for non-Turbo requests only (curl, tests without Capybara/Turbo);
        # the real browser flow always hits format.turbo_stream.
        format.html { redirect_to @item, notice: "Item created." }
      end
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

  # Cloudinary's upload (via ActiveStorage) can time out transiently. Retry the whole save a
  # couple of times with a short backoff before giving up — cheaper and safer than reaching
  # into Cloudinary/Faraday internals, and covers the actual failure mode reported (Faraday::
  # TimeoutError / Net::ReadTimeout during @item.save's photo attach).
  def save_item_with_retry(item, attempt: 1)
    item.save
  rescue *RETRYABLE_UPLOAD_ERRORS => e
    Rails.logger.warn("Item save attempt #{attempt} failed (#{e.class}): #{e.message}")
    if attempt < MAX_SAVE_ATTEMPTS
      sleep(attempt) # 1s, then 2s
      save_item_with_retry(item, attempt: attempt + 1)
    else
      Rails.logger.error("Item save failed after #{MAX_SAVE_ATTEMPTS} attempts (#{e.class}): #{e.message}")
      item.errors.add(:base, "We couldn't save your photo right now — check your connection and try again.")
      false
    end
  end

  # "Set Reminder" on the single-path skip case (_single_path_result): the item
  # is already saved by the time we get here. If its waste category has a real
  # fixed collection day, add the schedule ourselves and jump to the month it
  # falls in. Otherwise there's no date to guess — send the user to the
  # calendar with the item preselected so they can add it manually once they
  # know their date (e.g. after contacting the ward office for large-sized
  # waste or an appliance-recycling-law item).
  def handle_set_reminder(item)
    scheduled_date = Schedule.next_collection_date_for(item.waste_category_key)

    if scheduled_date
      current_user.schedules.create!(item: item, title: item.title, scheduled_date: scheduled_date)
      redirect_to schedules_path(start_date: scheduled_date),
                  notice: "Added to your calendar for #{scheduled_date.strftime('%B %-d')}."
    else
      redirect_to schedules_path(item_id: item.id),
                  notice: "#{item.waste_category&.name || 'This item'} doesn't have a fixed collection day — " \
                          "contact Meguro ward to find yours, then add it to the calendar below."
    end
  end

  def set_item
    @item = current_user.items.find(params[:id])
  end

  def photos
    params[:photos]
  end

  # A best-effort English title from the identification, used before any AI copy
  # exists: as the preview Item's title in #identify and as the saved record's
  # title in #create. identify's hash has symbol keys (ItemIdentifier), create's
  # local has string keys (item_params.slice), so read both.
  def provisional_title(identification)
    [identification["brand"] || identification[:brand],
     identification["category"] || identification[:category]].compact_blank.join(" ").presence || "Unlisted item"
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
