# lib/ial_parser/tokenizer.rb
# frozen_string_literal: true

require_relative 'errors'

module IALParser
  class Tokenizer
    Token = Struct.new(:raw, :position, :quoted?, :quote_type) do
      def inspect
        "#<Token raw=#{raw.inspect}, pos=#{position}, quoted?=#{quoted?}, quote=#{quote_type}>"
      end
    end

    QUOTE_TYPES = {
      '"' => :double,
      "'" => :single,
      "`" => :backtick
    }.freeze

    class << self
      def tokenize(string, strict: false)
        tokens = []
        i = 0
        len = string.length

        while i < len
          i = skip_whitespace(string, i)
          break if i >= len

          raw, new_i, quoted, quote_type = extract_token(string, i, strict: strict)
          tokens << Token.new(raw, i, quoted, quote_type)
          i = new_i
        end

        tokens
      end

      private

      def skip_whitespace(str, i)
        i += 1 while i < str.length && str[i] == ' '
        i
      end

      def extract_token(str, start, strict:)
        i = start
        buffer = +''
        in_quotes = false
        quote_char = nil
        quote_type = nil
        escaped = false
        quote_start_pos = start

        while i < str.length
          char = str[i]

          if escaped
            buffer << char
            escaped = false
            i += 1
            next
          end

          if char == '\\'
            escaped = true
            buffer << char
            i += 1
            next
          end

          if QUOTE_TYPES.key?(char)
            if in_quotes && char == quote_char
              buffer << char
              in_quotes = false
              # quote_char НЕ сбрасываем — нужен для проверки
              i += 1
            elsif !in_quotes
              buffer << char
              in_quotes = true
              quote_char = char
              quote_type = QUOTE_TYPES[char]
              quote_start_pos = i
              i += 1
            else
              buffer << char
              i += 1
            end
          elsif char == ' ' && !in_quotes
            break
          else
            buffer << char
            i += 1
          end
        end

        # Ошибки
        if in_quotes
          msg = "Unterminated quote starting at position #{quote_start_pos}"
          raise UnterminatedQuoteError, msg if strict
        end

        if escaped
          msg = "Escape sequence at end of token, position #{i - 1}"
          raise EscapeAtEndError, msg if strict
        end

        quoted = !!quote_type

        [buffer, i, quoted, quote_type]
      end
    end
  end
end