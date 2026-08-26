class ItemIdentifier
  def initialize(photos)
    @photos = photos
  end

  def call
    prompt = <<-PROMPT
      Identify this secondhand item. Look closely for a visible brand/manufacturer name or
      model number (e.g. on a label or panel) and include them if you can make them out —
      only leave them null if genuinely not legible, don't guess.

      The seller is always separately asked these four fixed questions, so follow_up_questions
      must never ask about them or anything covered by them:
        - Approximately how old is the item?
        - Is it in working/usable condition?
        - Any known defects or damage not visible in the photo?
        - Any accessories, manual, or original packaging included?

      For follow_up_questions, give up to 3 short questions (or an empty array if none are
      needed — that's the common case for large appliances, since the four fixed questions
      above already cover most of what's needed) about things you genuinely cannot determine
      from the photo, tailored to this specific item type. Rules:
        - Only ask what's NOT visible/determinable from the photo.
        - Never ask about color, shape, or anything clearly visible in the image.
        - Never ask anything that would require the seller to use a tool (tape measure,
          thermometer), check a spec plate/manual, or look something up. This means: NEVER
          ask about dimensions, energy rating/class, wattage, voltage, capacity (liters,
          cubic feet, etc.), refrigerant/coolant type, compressor type, or any other technical
          spec — full stop, regardless of item type.
        - Keep each question short (under 10 words).
        - Tailor to the item type, e.g.: shoes/clothing -> size, men's/women's/unisex/kids;
          small electronics -> what's included in the box; musical instruments ->
          maintenance/servicing history; sports equipment -> size/spec relevant to that sport;
          books/media -> language edition, volume number if part of a series.
        - Large appliances (fridge, washer, dryer, AC, TV, microwave): return an EMPTY array.
          The only exception is if brand or model_number is null because it genuinely
          wasn't legible in the photo — in that case you may ask the seller to check the
          label/nameplate for it, and nothing else.
    PROMPT

    chat = RubyLLM.chat(model: "gpt-4o").with_schema(ItemIdentificationSchema)
    response = chat.ask(prompt, with: @photos.map { |photo| photo.tempfile.path })

    response.content.symbolize_keys.tap { |result| Rails.logger.info("ItemIdentifier result: #{result}") }
  rescue StandardError => e
    Rails.logger.error("ItemIdentifier failed: #{e.message}")
    { name: nil, brand: nil, category: nil, model_number: nil, condition_guess: nil, follow_up_questions: [] }
  end
end
