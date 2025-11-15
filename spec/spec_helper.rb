# spec/spec_helper.rb
require "bundler/setup"

require_relative "../lib/ial_parser/parser"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end