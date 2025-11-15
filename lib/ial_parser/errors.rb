# lib/ial_parser/errors.rb
module IALParser
  class ParseError < StandardError; end
  class UnterminatedQuoteError < ParseError; end
  class EscapeAtEndError < ParseError; end
  class UnknownParameterType < ParseError; end
  class QuotingError < ParseError; end
  class AttributeError < ParseError; end
  class DuplicateIdError < AttributeError; end
  class DuplicateValueError < AttributeError; end
end
