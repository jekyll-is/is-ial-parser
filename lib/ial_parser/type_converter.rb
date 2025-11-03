# lib/ial_parser/type_converter.rb
# frozen_string_literal: true

module IALParser
  module TypeConverter
    class << self
      # raw_key → Symbol (всегда, т.к. ключ — всегда идентификатор)
      def convert_key(raw_key)
        raw_key
          .gsub('-', '_')
          .to_sym
      end

      # value + quoted? → Object
      # - quoted? → String
      # - иначе → null, число, true/false, валидный идентификатор → Symbol, иначе → String
      def convert_value(value, quoted:)
        if quoted
          value
        else
          case value
          when nil, "", "nil", "null"
            nil
          when "true"
            true
          when "false"
            false
          when /\A0x[0-9a-fA-F]+\z/
            value.to_i(16)
          when /\A0o[0-7]+\z/
            value.to_i(8)
          when /\A0b[01]+\z/
            value.to_i(2)
          when /\A-?\d+\z/
            value.to_i
          when /\A-?\d+\.\d+\z/
            value.to_f
          when /\A[a-z_][a-z0-9_]*\z/i
            value.to_sym
          else
            value
          end
        end
      end

    end
  end
end
