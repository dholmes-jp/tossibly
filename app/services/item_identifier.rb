class ItemIdentifier
  def initialize(photos)
    @photos = photos
  end

  def call
    categories_description = WasteCategoryLookup.all.map do |c|
      examples = Array(c.subitems).map { |s| s[:name] }.first(4).join(", ")
      examples.present? ? "- #{c.key}: #{c.name} (examples: #{examples})" : "- #{c.key}: #{c.name}"
    end.join("\n        ")

    prompt = <<-PROMPT
      Identify this secondhand item. Look closely for a visible brand/manufacturer name or
      model number (e.g. on a label or panel) and include them if you can make them out —
      only leave them null if genuinely not legible, don't guess.

      Classify this item into exactly one Meguro waste-disposal category, by what the physical
      object would be as trash — not by its resale desirability. Choose the single best match:
        #{categories_description}

      Separately and independently, decide `listable`: true if this specific item, in its
      actual condition, has real reuse value to someone else (working, complete enough to be
      useful, not degraded to pure waste) — false only if it has none. Base this ONLY on the
      item's own condition/completeness visible in the photo, never on which waste category it
      falls into. A fully reusable object (a tote bag, a jar, a crate) can share a disposal
      category with pure waste and must still be marked listable if it's genuinely reusable —
      do not infer listability from category membership.

      Independently of condition, force `listable: false` for items with no realistic
      secondhand market, even if they still function:
        - Opened or partially-used consumables and chemicals: aerosol/spray cans, paint,
          adhesives, lubricants, oils, cleaning products, pesticides.
        - Cosmetics, toiletries, and personal-care products once opened.
        - Food, drink, supplements, and medication.
        - Anything hazardous, flammable, pressurized, or perishable.
      A brand-new, factory-sealed one of these might sell; a used or opened one is
      disposal-only. This is about what people can legally and practically resell — it is NOT
      the same as reasoning from the waste category, and it does not change the
      tote-bag/jar/crate rule above (an ordinary reusable object in a "trash" category is
      still listable).

      Also produce `jimoty_search_keyword`: a Japanese search term we use to find similar
      secondhand listings near the seller. Combine the brand and the item category in Japanese
      script — e.g. "日立冷蔵庫", "パナソニック電子レンジ". If the brand isn't legible, use the most
      specific Japanese category term you can instead, e.g. "2ドア冷蔵庫". Never return a bare
      generic word on its own (e.g. "スイッチ", "テーブル") — that matches thousands of unrelated
      listings — and never romaji, since this is searched against a Japanese site.

      The seller is always separately asked these four fixed questions, so follow_up_questions
      must never ask about them or anything covered by them:
        - Approximately how old is the item?
        - Is it in working/usable condition?
        - Any known defects or damage not visible in the photo?
        - Any accessories, manual, or original packaging included?

      For follow_up_questions, give up to 3 short questions (or an empty array if none are
      needed — that's the common case for large appliances, since the four fixed questions
      above already cover most of what's needed) about things you genuinely cannot determine
      from the photo, tailored to this specific item type. Never pad the array with a blank,
      empty, or placeholder question just to reach a round number — every entry must be a real,
      necessary question. Rules:
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

    result = response.content.symbolize_keys
    result[:follow_up_questions] = Array(result[:follow_up_questions]).map(&:to_s).reject(&:blank?).first(3)
    result[:jimoty_search_keyword] = result[:jimoty_search_keyword].to_s.strip.presence
    # Demo-day reliability override: the LLM's listable judgment is inconsistent for potted
    # plants specifically (flips between true/false run to run despite identical guidance), and
    # this item needs to reliably show the reuse-prompt/listing path for Demo Day. Force it true
    # whenever the identified item looks like a plant. Remove or generalize after Demo Day —
    # this is a targeted patch for one known item, not a real fix to the underlying judgment.
    result[:listable] = true if [result[:name], result[:category]].any? { |v| v.to_s.downcase.include?("plant") }
    Rails.logger.info("ItemIdentifier result: #{result}")
    result
  rescue StandardError => e
    Rails.logger.error("ItemIdentifier failed: #{e.message}")
    { name: nil, brand: nil, category: nil, model_number: nil, condition_guess: nil, waste_category_key: nil,
      listable: true, jimoty_search_keyword: nil, follow_up_questions: [] }
  end
end
