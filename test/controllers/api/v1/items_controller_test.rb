require "test_helper"

class Api::V1::ItemsControllerTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://example.com:30'
    resource '/orders',
      :headers => :any,
      :methods => [:post]
  end
end
end
