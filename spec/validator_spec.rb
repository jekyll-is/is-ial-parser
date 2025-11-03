# spec/ial_parser/validator_spec.rb

require_relative 'spec_helper'

RSpec.describe IALParser::Validator do
  let(:options) { {} }
  subject { described_class.validate(classified_tokens, options) }

  def token(raw, position: 0, quoted: false, quote_type: :none)
    double('Token', raw: raw, position: position, quoted?: quoted, quote_type: quote_type)
  end

  def ct(type:, raw_key:, raw_value: nil, value: nil, token: nil)
    token ||= self.token(raw_key + (raw_value ? "=#{raw_value}" : ''), position: 0)
    double('ClassifiedToken',
           type: type,
           raw_key: raw_key,
           raw_value: raw_value,
           value: value,
           token: token)
  end

  describe '.validate' do
    # -----------------------------------------------------------------
    # :id
    # -----------------------------------------------------------------
    context 'with :id tokens' do
      let(:classified_tokens) do
        [
          ct(type: :id, raw_key: '#id1', value: 'id1', token: token('#id1', position: 0)),
          ct(type: :id, raw_key: '#id1', value: 'id1', token: token('#id1', position: 10))
        ]
      end

      context 'strict: true' do
        let(:options) { { strict: true } }
        it 'raises DuplicateIdError' do
          expect { subject }.to raise_error(
            IALParser::Validator::DuplicateIdError,
            "Duplicate id: 'id1' at positions 0 and 10"
          )
        end
      end

      context 'strict: false' do
        it 'returns warning' do
          expect(subject).to contain_exactly(
            "Duplicate id: 'id1' at positions 0 and 10"
          )
        end
      end
    end

    # -----------------------------------------------------------------
    # валидные ключи
    # -----------------------------------------------------------------
    context 'with valid keys' do
      let(:classified_tokens) do
        [
          ct(type: :attr, raw_key: 'count', raw_value: '42'),
          ct(type: :attr, raw_key: 'color', raw_value: nil),  # color=
          ct(type: :attr, raw_key: 'draft'),
          ct(type: :attr, raw_key: '_hidden'),
          ct(type: :attr, raw_key: 'API')
        ]
      end

      it 'returns no warnings' do
        expect(subject).to be_empty
      end
    end

    # -----------------------------------------------------------------
    # невалидные ключи
    # -----------------------------------------------------------------
    context 'with invalid keys' do
      let(:classified_tokens) do
        [
          ct(type: :attr, raw_key: '42', raw_value: nil),
          ct(type: :attr, raw_key: 'data-x', raw_value: '1'),
          ct(type: :attr, raw_key: '=red', raw_value: nil),
          ct(type: :attr, raw_key: '', raw_value: 'val'),   # empty key
          ct(type: :attr, raw_key: '3d', raw_value: nil)
        ]
      end

      context 'strict: true' do
        let(:options) { { strict: true } }
        it 'raises InvalidKeyError on first invalid key' do
          expect { subject }.to raise_error(
            IALParser::Validator::InvalidKeyError,
            /Invalid key: '42'/
          )
        end
      end

      context 'strict: false' do
        it 'collects all warnings' do
          expect(subject).to contain_exactly(
            "Invalid key: '42' at position 0 — must start with letter or '_', followed by letters, digits, or '_'",
            "Invalid key: 'data-x' at position 0 — must start with letter or '_', followed by letters, digits, or '_'",
            "Invalid key: '=red' at position 0 — must start with letter or '_', followed by letters, digits, or '_'",
            "Empty key at position 0",
            "Invalid key: '3d' at position 0 — must start with letter or '_', followed by letters, digits, or '_'"
          )
        end
      end
    end

    # -----------------------------------------------------------------
    # спец-префиксы
    # -----------------------------------------------------------------
    context 'with special prefixes' do
      let(:options) { { special_prefixes: ['@', '!'] } }

      let(:classified_tokens) do
        [
          ct(type: :special, raw_key: '@"Chapter 1"', raw_value: 'Chapter 1'),
          ct(type: :special, raw_key: '!draft'),
          ct(type: :special, raw_key: '@invalid')
        ]
      end

      it 'allows special prefixes' do
        expect(subject).to be_empty
      end
    end

    # -----------------------------------------------------------------
    # :ext – обычные случаи
    # -----------------------------------------------------------------
    context 'with :ext keys' do
      let(:classified_tokens) do
        [
          ct(type: :ext, raw_key: 'abbr:API', raw_value: 'REST'),
          ct(type: :ext, raw_key: 'index:keyword'),
          ct(type: :ext, raw_key: 'invalid:3d', raw_value: 'val')
        ]
      end

      context 'strict: true' do
        let(:options) { { strict: true } }
        it 'raises on invalid nested key' do
          expect { subject }.to raise_error(
            IALParser::Validator::InvalidKeyError,
            /Invalid nested key in extension: '3d'/
          )
        end
      end

      context 'strict: false' do
        it 'warns only on invalid nested key' do
          expect(subject).to contain_exactly(
            "Invalid nested key in extension: '3d' at position 0"
          )
        end
      end
    end

    # -----------------------------------------------------------------
    # :ext – граничные случаи
    # -----------------------------------------------------------------
    context 'edge cases for :ext' do
      let(:classified_tokens) do
        [
          ct(type: :ext, raw_key: ':empty', raw_value: 'val'),          # empty ext_name
          ct(type: :ext, raw_key: 'valid:', raw_value: nil),           # empty nested key
          ct(type: :ext, raw_key: 'valid::nested', raw_value: nil),    # double colon
          ct(type: :ext, raw_key: '3d:valid', raw_value: nil),         # invalid ext_name
          ct(type: :ext, raw_key: 'valid:3d', raw_value: nil)          # invalid nested key
        ]
      end

      context 'strict: false' do
        it 'collects all expected warnings' do
          expect(subject).to contain_exactly(
            "Empty extension name in ':empty' at position 0",
            "Empty nested key after ':' in 'valid:' at position 0",
            "Invalid nested key in extension: ':nested' at position 0",
            "Invalid extension name: '3d' at position 0",
            "Invalid nested key in extension: '3d' at position 0"
          )
        end
      end
    end

    # -----------------------------------------------------------------
    # регистронезависимость
    # -----------------------------------------------------------------
    context 'edge cases' do
      let(:classified_tokens) do
        [
          ct(type: :attr, raw_key: 'a', raw_value: nil),
          ct(type: :attr, raw_key: 'A', raw_value: nil),
          ct(type: :attr, raw_key: 'user_name', raw_value: nil)
        ]
      end

      it 'allows case-insensitive identifiers' do
        expect(subject).to be_empty
      end
    end
  end
end