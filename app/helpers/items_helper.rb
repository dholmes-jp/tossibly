module ItemsHelper
  ITEM_IMAGES = {
    "Wooden Chair" => "chair.jpg",
    "Chocolate Fountain" => "chocolate.jpg",
    "Hamster Cage" => "hamster.jpg",
    "Nintendo Switch 2" => "switch2.jpg",
    "Laptop" => "laptop.jpg"
  }.freeze

  def item_image(item)
    ITEM_IMAGES[item.title]
  end
end
