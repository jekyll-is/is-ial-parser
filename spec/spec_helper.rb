# spec/spec_helper.rb
require "bundler/setup"

require_relative "../lib/ial_parser/errors"
require_relative "../lib/ial_parser/tokenizer"
require_relative "../lib/ial_parser/classifier"
require_relative "../lib/ial_parser/type_converter"
require_relative "../lib/ial_parser/validator"
require_relative "../lib/ial_parser/assembler"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
