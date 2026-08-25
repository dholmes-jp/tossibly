class ItemIdentifier
  def initialize(photos)
    @photos = photos
  end

  def call
    prompt = <<-PROMPT
      Identify this secondhand item. Respond with strict JSON only, matching this shape:
      {
        "name": string, "brand": string|null, "category": string, "model_number": string|null,
        "condition_guess": string,
        "follow_up_questions": [string, ...]  // 2-4 short questions a seller should answer
                                                // (e.g. age, working condition, scratches/defects, accessories included)
      }
    PROMPT

    chat = RubyLLM.chat(model: "gpt-4o-mini")
    response = chat.ask(prompt, with: @photos.map { |photo| photo.tempfile.path })

    JSON.parse(response.content, symbolize_names: true)
  rescue StandardError => e
    Rails.logger.error("ItemIdentifier failed: #{e.message}")
    { name: nil, brand: nil, category: nil, model_number: nil, condition_guess: nil, follow_up_questions: [] }
  end
end
