
require 'set'

require_relative 'errors'

module IALParser

  class << self

    def parse source, **options
      result = {}

      tokenize source, **options do |token, position, quoting|
        parsed = parse_token token, position, quoting, **options
        append_token result, parsed, **options if parsed
      end

      result
    end

    ESCAPE = "\\"
    QUOTES = Set['"', "'"]
    SPACES = /\s/

    private

    Token = Struct::new :type, :key, :extension, :value, :quotes, keyword_init: true

    def append_token target, token, **options
      multiple_values = Set[options[:multiple_values] || []]
      case token.type 
      when :id
        raise DuplicateIdError, "Duplicate id attribute" if target[:id]
        target[:id] = token.value
      when :classes
        target[:classes] ||= Set[]
        target[:classes] += token.value
      when :special
        if multiple_values === token.key
          target[token.key] ||= []
          target[token.key] << token.value
          target[:_quotes] ||= {}
          target[:_quotes][token.key] ||= []
          target[:_quotes][token.key] << token.quotes
        else
          raise DuplicateValueError, "Duplicate value for special attribute '#{token.key}'" if target.has_key?(token.key)
          target[token.key] = token.value
          if token.quotes
            target[:_quotes] ||= {}
            target[:_quotes][token.key] = token.quotes
          end
        end
      when :attribute
        if multiple_values === token.key
          target[token.key] ||= []
          target[token.key] << token.value
          target[:_quotes] ||= {}
          target[:_quotes][token.key] ||= []
          target[:_quotes][token.key] << token.quotes
        else
          raise DuplicateValueError, "Duplicate value for attribute '#{token.key}'" if target.has_key?(token.key)
          target[token.key] = token.value
          if token.quotes
            target[:_quotes] ||= {}
            target[:_quotes][token.key] = token.quotes
          end
        end
      when :extension
        xkey = :"#{token.extension}:#{token.key}"
        if multiple_values === xkey
          target[token.extension] ||= {}
          target[token.extension][token.key] ||= []
          target[token.extension][token.key] << token.value
          target[:_quotes] ||= {}
          target[:_quotes][xkey] ||= []
          target[:_quotes][xkey] << token.quotes
        else
          target[token.extension] ||= {}
          raise DuplicateValueError, "Duplicate value for attribute '#{xkey}'" if target[token.extension].has_key?(token.key)
          target[token.extension][token.key] = token.value
          if token.quotes
            target[:_quotes] ||= {}
            target[:_quotes][xkey] = token.quotes
          end
        end
      when :unknown
        target[:_unknown] ||= []
        target[:_unknown] << token.value
        target[:_quotes] ||= {}
        target[:_quotes][:_unknown] ||= []
        target[:_quotes][:_unknown] << token.quotes
      end
    end

    def parse_token source, position, quoting, **options
      strict_mode = !!options[:strict]
      unquote = !options[:preserve_quotes]
      unescape = !options[:preserve_escape]
      allow_unknown = !!options[:allow_unknown]
      convert_types = !options[:raw_string_values]

      special_prefixes = options[:special_prefixes] || []
      # multiple_values = options[:multiple_values] || []

      if special_prefixes.include?(source[0])
        quoting = shift_quoting quoting, 1
        value, quotes = parse_value source[1..], quoting, unquote: unquote, unescape: unescape, convert_types: convert_types 
        return Token::new type: :special, key: source[0].to_sym, value: value, quotes: quotes
      end

      case source
      when /^#/
        quoting = shift_quoting quoting, 1
        value, quotes = parse_value source[1..], quoting, unquote: unquote, unescape: unescape, convert_types: convert_types      
        return Token::new type: :id, value: value, quotes: quotes
      when /^\./
        quoting = shift_quoting quoting, 1
        value = parse_classes source[1..]      
        return Token::new type: :classes, value: value
      when /^[a-z_][a-z0-9_\-]*:/i
        colon_position = $~.end(0)
        extension = convert_key source[.. colon_position - 2]
        quoting = shift_quoting quoting, colon_position
        token = parse_token source[colon_position ..], position + colon_position, quoting, **options
        if token
          token.type = :extension
          token.extension = extension
        end
        return token
      when /^[a-z_][a-z0-9_\-]*=/i
        equal_position = $~.end(0)
        key = convert_key source[.. equal_position - 2]
        quoting = shift_quoting quoting, equal_position
        value, quotes = parse_value source[equal_position ..], quoting, unquote: unquote, unescape: unescape, convert_types: convert_types
        return Token::new type: :attribute, key: key, value: value, quotes: quotes
      when /^[a-z_][a-z0-9_\-]*$/i
        key = convert_key source
        return Token::new type: :attribute, key: key, value: true
      else 
        if allow_unknown
          value, quotes = parse_value(source, quoting, unquote: unquote, unescape: unescape, convert_types: convert_types)
          return Token::new(type: :unknown, key: :"", value: source, quotes: quotes)
        else
          msg = "Unknown parameter: #{ source.inspect } at #{ position }"
          if strict_mode
            raise UnknownParameterType, msg
          else
            warn msg
            return nil
          end
        end
      end
    end    

    def parse_classes source
      source.split(/\./)
    end

    def convert_key source
      source.gsub(/-/, '_').to_sym
    end

    def shift_quoting quoting, shift
      result = []
      quoting.each do |q|
        result << [ q[0], q[1] - shift, q[2] - shift ]
      end
      result
    end

    def parse_value source, quoting, unquote:, unescape:, convert_types:
      raise QuotingError, "Multiple quoting is unsupported" if quoting.size > 1
      value = nil
      quotes = nil
      if quoting.size == 1
        quote = quoting.first
        raise QuotingError, "Partial quoting is unsupported" if quote[1] != 0 || quote[2] != source.length - 1

        if unquote
          value = source[1..-2]
        else
          value = source
        end
        quotes = quote[0]
      else 
        value = source
      end

      value = unescape value, quotes if unescape
      value = convert_value value if convert_types && !quotes

      [value, quotes]
    end

    def unescape source, quotes
      if quotes == "'"
        source.gsub(/\\\\/, "\\")
              .gsub(/\'/, "'")
      else
        source.gsub(/\\n/, "\n")
              .gsub(/\\r/, "\r")
              .gsub(/\\t/, "\t")
              .gsub(/\\(.)/, '\1')
      end
    end

    def convert_value value
      case value
      when nil, "", "nil", "null"
        nil
      when "true"
        true
      when "false"
        false
      when /^0x[0-9a-fA-F]+$/
        value.to_i(16)
      when /^0o[0-7]+$/
        value.to_i(8)
      when /^0b[01]+$/
        value.to_i(2)
      when /^-?\d+$/
        value.to_i
      when /^-?\d+\.\d+$/
        value.to_f
      when /^[a-z_][a-z0-9_]*$/i
        value.to_sym
      else
        value
      end
    end

    def tokenize source, **options
      return to_enum(:tokenize, source, **options) unless block_given?

      i = 0
      len = source.length
      while i < len 
        i = skip_spaces source, i
        break unless i < len
        start = i
        token, i, quoting = extract_token source, start, **options
        yield token, start, quoting if token
      end
    end

    def skip_spaces source, start
      i = start
      while i < source.length && source[i].match?(SPACES)
        i += 1
      end
      i
    end

    def extract_token source, start, **options
      # special_prefixes = options[:special_prefixes] || []
      strict_mode = !!options[:strict]

      buffer = +''
      escaped = false
      in_quotes = false
      quote_char = nil
      quote_start = nil
      quoting = []
      i = start
      while i < source.length 
        ch = source[i]

        if escaped
          buffer << ch
          escaped = false
          i += 1
          next
        end

        if ch == ESCAPE
          buffer << ch
          escaped = true
          i += 1
          next
        end

        if QUOTES === ch
          if in_quotes && quote_char == ch
            buffer << ch
            in_quotes = false
            quoting << [quote_char, quote_start-start, i-start]
            quote_start = nil
            quote_char = nil
            i += 1
          elsif !in_quotes
            buffer << ch
            in_quotes = true
            quote_start = i
            quote_char = ch
            i += 1
          else                            # Не та кавычка, берем неизмененной
            buffer << ch
            i += 1
          end
        elsif !in_quotes && ch.match?(SPACES)
          break
        else
          buffer << ch
          i += 1
        end
      end

      if in_quotes
        msg = "Unterminated quote starting at #{ quote_start - start } (#{ quote_start })"
        if strict_mode
          raise UnterminatedQuoteError, msg
        else
          warn msg
          return [nil, i, quoting]
        end
      end

      if escaped
        msg = "Escape character at end, position #{ i - 1 }"
        if strict_mode 
          raise EscapeAtEndError, msg
        else
          warn msg
          return [nil, i, quoting]
        end
      end

      [buffer, i, quoting]
    end

  end

end
