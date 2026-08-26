class ItemDescriber
  def initialize(identification, answers)
    @identification = identification
    @answers = answers
  end

  def call
    prompt = <<~PROMPT
      Given this item identification: #{@identification.to_json}
      And these seller-provided answers: #{@answers.to_json}

      Write a marketplace listing.
    PROMPT

    chat = RubyLLM.chat(model: "gpt-4o-mini").with_schema(ItemListingSchema)
    response = chat.ask(prompt)

    response.content.symbolize_keys
  rescue StandardError => e
    Rails.logger.error("ItemDescriber failed: #{e.message}")
    nil
  end
end
