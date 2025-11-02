# spec/tokenizer_spec.rb
require_relative "spec_helper"

RSpec.describe IALParser::Tokenizer do
  describe ".tokenize" do
    it "handles value in quotes" do
      input = 'title="Hello world"'
      tokens = described_class.tokenize(input)
      expect(tokens[0].raw).to eq('title="Hello world"')
    end

    it "handles special prefix with quotes" do
      input = '@"Chapter 1"'
      tokens = described_class.tokenize(input)
      expect(tokens[0].raw).to eq('@"Chapter 1"')
    end

    it "preserves escape in value" do
      input = 'index:API=REST\ API'
      tokens = described_class.tokenize(input)
      expect(tokens[0].raw).to eq('index:API=REST\ API')
    end

    it "splits unquoted tokens" do
      input = 'count=42 active hidden'
      tokens = described_class.tokenize(input)
      expect(tokens.map(&:raw)).to eq(['count=42', 'active', 'hidden'])
    end

    it "raises on unterminated quote in strict mode" do
      input = 'title="Hello'
      expect {
        described_class.tokenize(input, strict: true)
      }.to raise_error(IALParser::UnterminatedQuoteError)
    end

    it "does not raise in lax mode" do
      input = 'title="Hello'
      tokens = described_class.tokenize(input, strict: false)
      expect(tokens[0].raw).to eq('title="Hello')
    end

    it "full example" do
      input = '.term #def1 count=42 active=true draft=null @"Chapter 1" index:API=REST\ API'
      tokens = described_class.tokenize(input)
      expected = [
        '.term',
        '#def1',
        'count=42',
        'active=true',
        'draft=null',
        '@"Chapter 1"',
        'index:API=REST\ API'
      ]
      expect(tokens.map(&:raw)).to eq(expected)
    end
  end
end
