class JimotyCategorySelector
  FILE_PATH = Rails.root.join(
    "config",
    "jimoty_categories.yml"
  )

  def initialize
    @data = YAML.load_file(FILE_PATH)
  end

  def call(item_information)
    categories = top_categories

    selected_category = choose_category(
      item_information,
      categories
    )

    return nil unless selected_category

    result = {
      category_value: selected_category["value"]
    }

    # Stop if there is no next level
    return result unless selected_category["children"]

    selected_large_genre = choose_category(
      item_information,
      selected_category["children"]
    )

    return result unless selected_large_genre

    result[:large_genre_value] =
      selected_large_genre["value"]

    # Stop if there is no next level
    return result unless selected_large_genre["children"]

    selected_medium_genre = choose_category(
      item_information,
      selected_large_genre["children"]
    )

    return result unless selected_medium_genre

    result[:medium_genre_value] =
      selected_medium_genre["value"]

    result
  end

  def top_categories
    @data["category_group"]["children"]
  end

  def find_by_value(categories, value)
    categories.find do |category|
      category["value"] == value.to_s
    end
  end

  private

  def choose_category(item_information, categories)
    options = categories.map do |category|
      "#{category['value']}: #{category['name']}"
    end.join("\n")

    prompt = <<~PROMPT
      Given this item information:

      #{item_information.to_json}

      Choose the single most appropriate Jimoty category
      from the options below.

      #{options}

      Return the numeric value of exactly one category.

      For example:
      If you choose "1102: キッチン家電",
      return 1102.

      Do not return the category name.
      Do not create a new value.
      You must choose one of the provided values.
    PROMPT

    chat = RubyLLM
           .chat(model: "gpt-4o")
           .with_schema(JimotyCategoryChoiceSchema)

    response = chat.ask(prompt)

    value = response.content["value"]

    puts "=========================="
    puts "OPTIONS:"
    puts options
    puts
    puts "LLM VALUE: #{value.inspect}"
    puts "=========================="

    find_by_value(categories, value)
  end
end
