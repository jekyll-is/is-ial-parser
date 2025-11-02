# is-ial-parser.gemspec
Gem::Specification.new do |s|
  s.name        = "is-ial-parser"
  s.version     = "0.1.0"
  s.summary     = "Universal IAL parser for Jekyll"
  s.description = "Parses Inline Attribute Lists with extensions, quotes, interpolation"
  s.authors     = ["Ivan Shikhalev"]
  s.email       = ["shikhalev@gmail.com"]
  s.files       = Dir["lib/**/*", "README.md", "LICENSE"]
  s.homepage    = "https://github.com/jekyll-is/is-ial-parser"
  s.license     = "GPL-3.0-or-later"

  s.required_ruby_version = "~> 3.4"

  s.add_development_dependency "rspec", "~> 3.13"
  s.add_development_dependency "rake", "~> 13.3"
end
