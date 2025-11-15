
require_relative 'spec_helper'

RSpec.describe IALParser do

  describe ".parse" do

    it "parse common sample" do
      source = '@/home/ivan scan=false link= title="Bla-bla-bla ololo" .note.italic #header ext:sym=blabla\ ololo'
      result = IALParser::parse source, special_prefixes: ['@']

      expected = {
        "@": "/home/ivan", 
        scan: false, 
        link: nil, 
        title: "Bla-bla-bla ololo", 
        _quotes: {
          title: "\""
          }, 
        classes: Set["note", "italic"], 
        id: :header, 
        ext: {
          sym: "blabla ololo"
          }
        }
      expect(result).to eq(expected)
    end

  end

end