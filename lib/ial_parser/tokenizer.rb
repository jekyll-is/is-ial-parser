# lib/ial_parser/tokenizer.rb
# frozen_string_literal: true

require_relative 'errors'

module IALParser
  class Tokenizer
    Token = Struct.new(:raw, :position)

    class << self
      def tokenize(string, strict: false)
        tokens = []
        i = 0
        len = string.length

        while i < len
          i = skip_whitespace(string, i)
          break if i >= len

          raw, new_i = extract_token(string, i, strict: strict)
          tokens << Token.new(raw, i)
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
        escaped = false

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

          if QUOTES.include?(char)
            if in_quotes && char == quote_char
              buffer << char
              in_quotes = false
              quote_char = nil
              i += 1
            elsif !in_quotes
              buffer << char
              in_quotes = true
              quote_char = char
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

        # Проверка незакрытой кавычки
        if in_quotes
          msg = "Unterminated quote starting near position #{start}"
          raise UnterminatedQuoteError, msg if strict
        end

        # Проверка экранирования в конце
        if escaped
          msg = "Escape at end of token, position #{i - 1}"
          raise EscapeAtEndError, msg if strict
        end

        [buffer, i]
      end

      QUOTES = %w[" ' `].freeze
    end
  end
end
