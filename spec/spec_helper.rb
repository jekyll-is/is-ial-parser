# spec/spec_helper.rb
require "bundler/setup"
require_relative "../lib/ial_parser/tokenizer"
require_relative "../lib/ial_parser/errors"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
