# spec/tokenizer_spec.rb
require_relative "spec_helper"

RSpec.describe IALParser::Tokenizer do
  let(:token_class) { described_class::Token }

  describe ".tokenize" do
    it "handles double quotes" do
      input = 'title="Hello world"'
      tokens = described_class.tokenize(input)
      expect(tokens[0].raw).to eq('title="Hello world"')
      expect(tokens[0].quoted?).to be true
      expect(tokens[0].quote_type).to eq(:double)
    end

    it "handles single quotes" do
      input = "title='Hello'"
      tokens = described_class.tokenize(input)
      expect(tokens[0].quoted?).to be true
      expect(tokens[0].quote_type).to eq(:single)
    end

    it "handles backticks (Liquid)" do
      input = "`{{page.title}}`"
      tokens = described_class.tokenize(input)
      expect(tokens[0].quoted?).to be true
      expect(tokens[0].quote_type).to eq(:backtick)
    end

    it "preserves escape in value" do
      input = 'index:API=REST\ API'
      tokens = described_class.tokenize(input)
      expect(tokens[0].raw).to eq('index:API=REST\ API')
      expect(tokens[0].quoted?).to be false
    end

    it "splits unquoted tokens" do
      input = 'count=42 active hidden'
      tokens = described_class.tokenize(input)
      expect(tokens.map(&:raw)).to eq(['count=42', 'active', 'hidden'])
      expect(tokens[0].quoted?).to be false
    end

    it "raises on unterminated quote in strict mode" do
      input = 'title="Hello'
      expect {
        described_class.tokenize(input, strict: true)
      }.to raise_error(IALParser::UnterminatedQuoteError, /position 6/)
    end

    it "does not raise in lax mode" do
      input = 'title="Hello'
      tokens = described_class.tokenize(input, strict: false)
      expect(tokens[0].raw).to eq('title="Hello')
      expect(tokens[0].quoted?).to be true
      expect(tokens[0].quote_type).to eq(:double)
    end

    it "full example with all quote types" do
      input = '.term #def1 title="Hi" name=\'Bob\' cmd=`echo {{x}}` @"Chapter" !draft'
      tokens = described_class.tokenize(input)
      expected = [
        ['.term', false, nil],
        ['#def1', false, nil],
        ['title="Hi"', true, :double],
        ['name=\'Bob\'', true, :single],
        ['cmd=`echo {{x}}`', true, :backtick],
        ['@"Chapter"', true, :double],
        ['!draft', false, nil]
      ]
      result = tokens.map { |t| [t.raw, t.quoted?, t.quote_type] }
      expect(result).to eq(expected)
    end
  end
end
