# spec/type_converter_spec.rb

require 'spec_helper'
require 'ial_parser/tokenizer'
require 'ial_parser/classifier'
require 'ial_parser/type_converter'

RSpec.describe IALParser::TypeConverter do
  let(:tokenizer) { IALParser::Tokenizer }
  let(:classifier) { IALParser::Classifier }

  # Создаёт ClassifiedToken из строки IAL-фрагмента
  # Например: "title=\"Hi\"" → ct с value="Hi", quoted?: true
  def ct_from_string(str, special_prefixes: ['@', '!'])
    tokens = tokenizer.tokenize(str, strict: false)
    classifier.classify(tokens.first, special_prefixes: special_prefixes)
  end

  describe '.convert_key' do
    it 'converts hyphenated keys to underscored symbols' do
      expect(described_class.convert_key('data-x')).to eq(:data_x)
      expect(described_class.convert_key('api-key')).to eq(:api_key)
    end

    it 'preserves uppercase in symbols' do
      expect(described_class.convert_key('API')).to eq(:API)
      expect(described_class.convert_key('XML')).to eq(:XML)
    end

    it 'handles empty string' do
      expect(described_class.convert_key('')).to eq(:"")
    end
  end

  describe '.convert_value' do
    context 'when value is quoted' do
      it 'returns the value as string, regardless of content' do
        expect(described_class.convert_value('Hi', quoted: true)).to eq('Hi')
        expect(described_class.convert_value('', quoted: true)).to eq('')
        expect(described_class.convert_value('nil', quoted: true)).to eq('nil')
        expect(described_class.convert_value('null', quoted: true)).to eq('null')
        expect(described_class.convert_value('true', quoted: true)).to eq('true')
        expect(described_class.convert_value('0xFF', quoted: true)).to eq('0xFF')
        expect(described_class.convert_value('\"escaped\"', quoted: true)).to eq('\"escaped\"')
      end
    end

    context 'when value is unquoted' do
      it 'handles nil (flag case)' do
        expect(described_class.convert_value(nil, quoted: false)).to eq(nil)
      end

      it 'handles empty string' do
        expect(described_class.convert_value('', quoted: false)).to eq(nil)
        expect(described_class.convert_value('', quoted: true)).to eq('')
      end

      it 'converts "null" to nil' do
        expect(described_class.convert_value('null', quoted: false)).to eq(nil)
      end

      it 'converts booleans' do
        expect(described_class.convert_value('true', quoted: false)).to eq(true)
        expect(described_class.convert_value('false', quoted: false)).to eq(false)
      end

      context 'number systems' do
        it 'converts hexadecimal (0x)' do
          expect(described_class.convert_value('0xFF', quoted: false)).to eq(255)
          expect(described_class.convert_value('0xABC', quoted: false)).to eq(2748)
          expect(described_class.convert_value('0x0', quoted: false)).to eq(0)
          expect(described_class.convert_value('0x10', quoted: false)).to eq(16)
        end

        it 'converts octal (0o)' do
          expect(described_class.convert_value('0o777', quoted: false)).to eq(511)
          expect(described_class.convert_value('0o10', quoted: false)).to eq(8)
          expect(described_class.convert_value('0o0', quoted: false)).to eq(0)
        end

        it 'converts binary (0b)' do
          expect(described_class.convert_value('0b1010', quoted: false)).to eq(10)
          expect(described_class.convert_value('0b1111', quoted: false)).to eq(15)
          expect(described_class.convert_value('0b0', quoted: false)).to eq(0)
          expect(described_class.convert_value('0b1', quoted: false)).to eq(1)
        end

        it 'rejects invalid number literals and treats as string' do
          expect(described_class.convert_value('0xGG', quoted: false)).to eq('0xGG')
          expect(described_class.convert_value('0o8', quoted: false)).to eq('0o8')
          expect(described_class.convert_value('0b2', quoted: false)).to eq('0b2')
          expect(described_class.convert_value('0x', quoted: false)).to eq('0x')
          expect(described_class.convert_value('0o', quoted: false)).to eq('0o')
          expect(described_class.convert_value('0b', quoted: false)).to eq('0b')
        end
      end

      it 'converts decimal integers' do
        expect(described_class.convert_value('42', quoted: false)).to eq(42)
        expect(described_class.convert_value('-100', quoted: false)).to eq(-100)
        expect(described_class.convert_value('0', quoted: false)).to eq(0)
      end

      it 'converts floating-point numbers' do
        expect(described_class.convert_value('3.14', quoted: false)).to eq(3.14)
        expect(described_class.convert_value('-0.5', quoted: false)).to eq(-0.5)
        expect(described_class.convert_value('100.0', quoted: false)).to eq(100.0)
      end

      it 'rejects invalid numbers and treats as string' do
        expect(described_class.convert_value('42a', quoted: false)).to eq('42a')
        expect(described_class.convert_value('3.14.1', quoted: false)).to eq('3.14.1')
        expect(described_class.convert_value('.', quoted: false)).to eq('.')
      end

      context 'valid identifiers → symbols' do
        it 'converts valid Ruby identifiers to symbols' do
          expect(described_class.convert_value('draft', quoted: false)).to eq(:draft)
          expect(described_class.convert_value('API', quoted: false)).to eq(:API)
          expect(described_class.convert_value('_hidden', quoted: false)).to eq(:_hidden)
          expect(described_class.convert_value('data3', quoted: false)).to eq(:data3)
          expect(described_class.convert_value('XMLParser', quoted: false)).to eq(:XMLParser)
        end
      end

      context 'invalid identifiers → strings' do
        it 'keeps invalid identifiers as strings' do
          expect(described_class.convert_value('3d', quoted: false)).to eq('3d')
          expect(described_class.convert_value('-draft', quoted: false)).to eq('-draft')
          expect(described_class.convert_value('hello world', quoted: false)).to eq('hello world')
          expect(described_class.convert_value('data-x', quoted: false)).to eq('data-x')
          expect(described_class.convert_value('!flag', quoted: false)).to eq('!flag')
          expect(described_class.convert_value('café', quoted: false)).to eq('café')  # non-ASCII
        end
      end
    end

    context 'integration with ClassifiedToken' do
      it 'correctly handles real IAL fragments' do
        ct = ct_from_string('color=0xFF0000')
        expect(described_class.convert_value(ct.value, quoted: ct.token.quoted?)).to eq(16711680)

        ct = ct_from_string('mode="debug"')
        expect(described_class.convert_value(ct.value, quoted: ct.token.quoted?)).to eq('debug')

        ct = ct_from_string('count=42')
        expect(described_class.convert_value(ct.value, quoted: ct.token.quoted?)).to eq(42)

        ct = ct_from_string('hidden')
        expect(ct.value).to be_nil
        expect(described_class.convert_value(ct.value, quoted: ct.token.quoted?)).to eq(nil)
      end
    end
  end
end
