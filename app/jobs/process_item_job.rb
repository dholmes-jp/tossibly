class ProcessItemJob < ApplicationJob
  def perform(item, identification: {}, answers: {})
    identification = identification.symbolize_keys
    answers = answers.symbolize_keys

    attrs, jimoty_categories =
      if item.listable?
        build_listing(item, identification, answers)
      else
        [plain_listing(identification), {}]
      end

    item.update(
      attrs.merge(
        jimoty_category_value: jimoty_categories[:category_value],
        jimoty_large_genre_value: jimoty_categories[:large_genre_value],
        jimoty_medium_genre_value: jimoty_categories[:medium_genre_value],
        processed_at: Time.current
      )
    )
  rescue StandardError => e
    Rails.logger.error("ProcessItemJob failed for item #{item.id}: #{e.class}: #{e.message}")
    item.update(processed_at: Time.current)
  ensure
    broadcast_decision_card(item)
  end

  private

  def broadcast_decision_card(item)
    item.broadcast_replace_to(
      item,
      target: ActionView::RecordIdentifier.dom_id(item, :decision),
      partial: "items/decision_card",
      locals: { item: item }
    )
  end

  def build_listing(item, identification, answers)
    generated = describe_item(item, identification, answers).slice(*Item.column_names.map(&:to_sym))

    # ayaka added / start
    jimoty_categories = JimotyCategorySelector.new.call(
      { identification: identification, answers: answers, listing: generated }
    ) || {}
    # ayaka added / end

    nearby = NearbyListingSearch.call(item).to_item_attributes
    [generated.merge(nearby).merge(platform: "jimoty"), jimoty_categories]
  end

  def plain_listing(identification)
    plain_title = [identification[:brand],
                   identification[:category]].compact_blank.join(" ").presence || "Unlisted item"
    { title: plain_title, description: "Not offered on Jimoty — routed straight to disposal." }
  end

  def describe_item(item, identification, answers)
    tempfiles = item.photos.map do |photo|
      file = Tempfile.new(["photo", File.extname(photo.filename.to_s)], binmode: true)
      file.write(photo.blob.download)
      file.flush
      file
    end
    ItemDescriber.new(identification, answers, tempfiles.map(&:path)).call || {}
  ensure
    tempfiles&.each { |file| file.close! }
  end
end
