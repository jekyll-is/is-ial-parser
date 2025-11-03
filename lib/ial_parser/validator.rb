# lib/ial_parser/validator.rb
# frozen_string_literal: true

module IALParser
  module Validator
    class DuplicateIdError < StandardError; end
    class InvalidKeyError < StandardError; end

    IDENTIFIER_REGEX = /\A[a-z_][a-z0-9_]*\z/i

    def self.valid_identifier?(str)
      str && IDENTIFIER_REGEX.match?(str)
    end

    # @param classified_tokens [Array<ClassifiedToken>]
    # @param options [Hash]  – :strict, :special_prefixes
    # @return [Array<String>] warnings (only when strict: false)
    def self.validate(classified_tokens, options = {})
      warnings = []
      seen_ids = {}
      special_prefixes = Array(options[:special_prefixes]).map(&:to_s)

      classified_tokens.each do |ct|
        pos = ct.token.position

        case ct.type
        when :id
          id = ct.value
          if seen_ids.key?(id)
            msg = "Duplicate id: '#{id}' at positions #{seen_ids[id]} and #{pos}"
            options[:strict] ? raise(DuplicateIdError, msg) : warnings << msg
          else
            seen_ids[id] = pos
          end

        when :attr, :special
          raw_key = ct.raw_key.to_s

          # пустой ключ – всегда ошибка
          if raw_key.empty?
            msg = "Empty key at position #{pos}"
            options[:strict] ? raise(InvalidKeyError, msg) : warnings << msg
            next
          end

          is_special = special_prefixes.any? { |p| raw_key.start_with?(p) && raw_key.size > p.size }
          unless is_special || valid_identifier?(raw_key)
            msg = "Invalid key: '#{raw_key}' at position #{pos} — must start with letter or '_', followed by letters, digits, or '_'"
            options[:strict] ? raise(InvalidKeyError, msg) : warnings << msg
          end

        when :ext
          # Разбиваем только один раз: ext_name:nested_key
          parts = ct.raw_key.to_s.split(':', 2)
          ext_name   = parts[0] || ''
          nested_key = parts[1]

          # ---- ext_name -------------------------------------------------
          if ext_name.empty?
            msg = "Empty extension name in '#{ct.raw_key}' at position #{pos}"
            options[:strict] ? raise(InvalidKeyError, msg) : warnings << msg
            next
          end

          unless valid_identifier?(ext_name)
            msg = "Invalid extension name: '#{ext_name}' at position #{pos}"
            options[:strict] ? raise(InvalidKeyError, msg) : warnings << msg
          end

          # ---- nested_key -----------------------------------------------
          unless nested_key
            msg = "Missing nested key after ':' in '#{ct.raw_key}' at position #{pos}"
            options[:strict] ? raise(InvalidKeyError, msg) : warnings << msg
            next
          end

          if nested_key.empty?
            msg = "Empty nested key after ':' in '#{ct.raw_key}' at position #{pos}"
            options[:strict] ? raise(InvalidKeyError, msg) : warnings << msg
            next
          end

          # Если после первого `:` есть ещё один `:` – это уже часть nested_key
          # Пример: "valid::nested" → nested_key = ":nested"
          is_special = special_prefixes.any? { |p| nested_key.start_with?(p) && nested_key.size > p.size }
          unless is_special || valid_identifier?(nested_key)
            msg = "Invalid nested key in extension: '#{nested_key}' at position #{pos}"
            options[:strict] ? raise(InvalidKeyError, msg) : warnings << msg
          end
        end
      end

      warnings
    end
  end
end
