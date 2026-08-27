class ItemDescriber
  def initialize(identification, answers, photos)
    @identification = identification
    @answers = answers
    @photos = Array(photos).compact_blank
  end

  def call
    prompt = <<~PROMPT
      Given this item identification: #{@identification.to_json}
      And these seller-provided answers: #{@answers.to_json}
      And the attached photos of the item.

      Write this as a real Jimoty (ジモティー) classifieds listing — plain and practical, like a
      neighbor describing something they're passing along locally. This is NOT sales or marketing
      copy, so do not write it like one.

      Never use hype or superlative language anywhere in title, title_ja, description, or
      description_ja. Banned words/phrases (and their Japanese equivalents) include: "amazing,"
      "fantastic," "incredible deal," "must-have," "don't miss out," "act now," "steal," 掘り出し物,
      激安, 必見, お見逃しなく, 大チャンス. Do not replace them with other hype synonyms either —
      just state facts plainly.

      Look closely at the attached photos yourself — don't rely only on the identification summary.
      State the item and its actual condition plainly, including any visible wear, marks, scuffs,
      stains, or flaws visible in the photos. Do not soften, downplay, or omit them to make the
      listing sound better. Mention concrete visible details from the photos (exact colorway, a
      size or model printed on a label, wear on a sole or edge, tags or packaging still attached)
      instead of generic filler.

      List included accessories, box, or manual based on the seller's answers only — don't invent
      anything not mentioned.

      Keep sentences short and matter-of-fact. A brief note that pickup or handoff timing is
      flexible is fine. Do not include any call-to-action urging the buyer to act quickly or not
      miss out.

      Keep title and title_ja plain and descriptive — brand plus item plus a key spec like size or
      color — not a pitch headline.
    PROMPT

    chat = RubyLLM.chat(model: "gpt-4o").with_schema(ItemListingSchema)
    response = chat.ask(prompt, with: @photos.map { |photo| photo.tempfile.path })

    response.content.symbolize_keys
  rescue StandardError => e
    Rails.logger.error("ItemDescriber failed: #{e.message}")
    nil
  end
end
