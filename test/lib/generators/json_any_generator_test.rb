require "test_helper"
require "generators/json_any/json_any_generator"

class JsonAnyGeneratorTest < Rails::Generators::TestCase
  tests JsonAnyGenerator
  destination Rails.root.join("tmp/generators")
  setup :prepare_destination

  # test "generator runs without errors" do
  #   assert_nothing_raised do
  #     run_generator ["arguments"]
  #   end
  # end
end
