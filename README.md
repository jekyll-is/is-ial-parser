# is-ial-parser

Universal Inline Attribute List (IAL) parser for Kramdown and Jekyll plugins.

[![Gem Version](https://badge.fury.io/rb/is-ial-parser.svg?icon=si%3Arubygems)](https://badge.fury.io/rb/is-ial-parser)

## Version

+ **0.8.0** — pre-release.

## Overview

is-ial-parser is a Ruby gem designed to parse Inline Attribute Lists with support for extensions, quoting, interpolation, and type conversion. It helps process attribute strings typically embedded in markdown or static site generators like Jekyll, enabling enhanced control over element attributes, classes, IDs, and custom extensions.

Key features include:
- Parsing of IDs, classes, key-value attributes, and special prefixes.
- Support for quoted and escaped values.
- Conversion of string values to native Ruby types (booleans, numbers, symbols).
- Extensible attribute namespaces using colon-separated keys.
- Configurable strict mode with detailed error handling.
- Preservation of original quoting if needed.
- Comprehensive handling of edge cases and errors such as duplicate IDs or unterminated quotes.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'is-ial-parser', '~> 0.8.0'
```

Then execute:

```shell
bundle install
```

Or install it yourself as:

```shell
gem install is-ial-parser
```

## Usage

```ruby
require 'is-ial-parser'

source = '@/home/ivan scan=false link= title="Example title" .note.italic #header ext:sym=blabla\ ololo'
result = IALParser.parse(source, special_prefixes: ['@'])

# Result is a Hash with parsed keys and values:
puts result[:id]           # :header
puts result[:classes]      # Set['note', 'italic']
puts result[:"@"]          # "/home/ivan"
puts result[:scan]         # false
puts result[:title]        # "Example title"
puts result[:ext][:sym]    # "blabla ololo"
```

See the test/spec files for more usage examples and edge cases.

## Development

To run specs:

```shell
bundle exec rake spec
```

Test coverage includes parsing of classes, IDs, attributes, quoted and escaped strings, extensions, error conditions, and type conversions.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jekyll-is/is-ial-parser.

Please follow the existing code style and test coverage for any additions.

## License

The gem is available as open source under the terms of the GNU GPLv3 License.


