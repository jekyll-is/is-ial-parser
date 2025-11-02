# lib/ial_parser/errors.rb
module IALParser
  class ParseError < StandardError; end
  class UnterminatedQuoteError < ParseError; end
  class EscapeAtEndError < ParseError; end
end
