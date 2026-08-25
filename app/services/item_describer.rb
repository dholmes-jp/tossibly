class ItemDescriber
  def initialize(identification, answers)
    @identification = identification
    @answers = answers
  end

  def call
    prompt = <<~PROMPT
      Given this item identification: #{@identification.to_json}
      And these seller-provided answers: #{@answers.to_json}

      Write a marketplace listing. Respond with strict JSON only:
      {
        "title": string, "title_ja": string,
        "description": string, "description_ja": string,
        "category": string, "brand": string|null, "model_number": string|null,
        "suggested_price": integer|null, "disposal_fee": integer|null,
        "platform": "mercari"|"jimoty", "jimoty_category": string|null
      }
    PROMPT

    chat = RubyLLM.chat(model: "gpt-4o-mini")
    response = chat.ask(prompt)

    JSON.parse(response.content, symbolize_names: true)
  rescue StandardError => e
    Rails.logger.error("ItemDescriber failed: #{e.message}")
    nil
  end
end
