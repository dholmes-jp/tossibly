# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end


# db/seeds.rb

# Clear existing data
Item.destroy_all
User.destroy_all

# --------------------
# Users
# --------------------

user1 = User.create!(
  email: "user1@email.com",
  password: "secret",
  address: "2 Chome-11-3 Meguro, Meguro City, Tokyo",
  name: "James"
)

user2 = User.create!(
  email: "user2@email.com",
  password: "secret",
  address: "2 Chome-11-3 Meguro, Meguro City, Tokyo",
  name: "Eri"
)

# --------------------
# User 1 Items
# --------------------

Item.create!(
  user: user1,
  title: "Rice Cooker",
  title_ja: "炊飯器",
  category: "Kitchen Appliance",
  platform: "mercari",
  description: "5-cup rice cooker in good working condition. Some minor scratches from normal use.",
  description_ja: "5合炊きの炊飯器です。正常に動作します。通常使用による多少の傷があります。",
  age: 3,
  functional: true,
  brand: "Zojirushi",
  model_number: "NW-VA10",
  suggested_price: 5000,
  disposal_fee: 400,
  jimoty_category: "1"
)

Item.create!(
  user: user1,
  title: "Wooden Coffee Table",
  title_ja: "木製ローテーブル",
  category: "Furniture",
  platform: "jimoty",
  description: "Small wooden coffee table. Good condition with a few marks on the surface.",
  description_ja: "小さめの木製ローテーブルです。天板に多少の使用感がありますが、全体的に良好な状態です。",
  age: 4,
  functional: true,
  brand: "IKEA",
  model_number: "LACK",
  suggested_price: 1000,
  disposal_fee: 400,
  jimoty_category: "2"
)

Item.create!(
  user: user1,
  title: "Electric Fan",
  title_ja: "扇風機",
  category: "Home Appliance",
  platform: "mercari",
  description: "Compact electric fan with three speed settings. Works normally.",
  description_ja: "3段階の風量調節が可能なコンパクト扇風機です。正常に動作します。",
  age: 2,
  functional: true,
  brand: "Yamazen",
  model_number: "YLT-C30",
  suggested_price: 2500,
  disposal_fee: 400,
  jimoty_category: "1"
)

# --------------------
# User 2 Items
# --------------------

Item.create!(
  user: user2,
  title: "Microwave Oven",
  title_ja: "電子レンジ",
  category: "Kitchen Appliance",
  platform: "jimoty",
  description: "Simple microwave oven. Fully functional and clean inside.",
  description_ja: "シンプルな電子レンジです。正常に動作し、庫内もきれいな状態です。",
  age: 5,
  functional: true,
  brand: "Panasonic",
  model_number: "NE-E22A1",
  suggested_price: 3000,
  disposal_fee: 400,
  jimoty_category: "1"
)

Item.create!(
  user: user2,
  title: "Office Chair",
  title_ja: "オフィスチェア",
  category: "Furniture",
  platform: "jimoty",
  description: "Adjustable office chair with wheels. Some wear on the seat but still comfortable.",
  description_ja: "高さ調節可能なキャスター付きオフィスチェアです。座面に多少の使用感があります。",
  age: 4,
  functional: true,
  brand: "Nitori",
  model_number: "OC-001",
  suggested_price: 1500,
  disposal_fee: 400,
  jimoty_category: "2"
)

Item.create!(
  user: user2,
  title: "Computer Monitor",
  title_ja: "PCモニター",
  category: "Electronics",
  platform: "mercari",
  description: "24-inch Full HD monitor. Display works normally with no dead pixels.",
  description_ja: "24インチのフルHDモニターです。ドット抜けはなく、正常に表示されます。",
  age: 3,
  functional: true,
  brand: "Dell",
  model_number: "P2419H",
  suggested_price: 7000,
  disposal_fee: 400,
  jimoty_category: "3"
)

puts "Created #{User.count} users"
puts "Created #{Item.count} items"
