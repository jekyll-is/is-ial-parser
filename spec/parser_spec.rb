
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

    it "парсит пустую строку" do
      expect(IALParser.parse("")).to eq({})
    end

    it "корректно обрабатывает несколько id-тегов с ошибкой дублирования" do
      source = "#id1 #id2"
      expect { IALParser.parse(source) }.to raise_error(IALParser::DuplicateIdError)
    end

    it "поддерживает экранирование внутри кавычек" do
      source = 'title="This is a \"quoted\" word"'
      result = IALParser.parse(source)
      expect(result[:title]).to eq('This is a "quoted" word')
      expect(result[:_quotes][:title]).to eq('"')
    end

    it "выдает ошибку на незакрытые кавычки в строгом режиме" do
      source = 'title="Unclosed string'
      expect { IALParser.parse(source, strict: true) }.to raise_error(IALParser::UnterminatedQuoteError)
    end

    it "игнорирует незакрытые кавычки в нестрогом режиме с предупреждением" do
      source = 'title="Unclosed string'
      expect_warn = false
      expect(IALParser.parse(source, strict: false)).to eq({})
    end

    it "правильно парсит вложенные расширения" do
      source = 'ext1:key1=value1 ext2:key2=value2'
      result = IALParser.parse(source)
      expect(result[:ext1][:key1]).to eq(:value1)
      expect(result[:ext2][:key2]).to eq(:value2)
    end

    it "обрабатывает несколько классов без дублирования" do
      source = ".class1.class2.class1"
      result = IALParser.parse(source)
      expect(result[:classes]).to eq(Set.new(['class1', 'class2']))
    end

    it "конвертирует булевы и числовые значения" do
      source = "flag=true count=42 pi=3.14 hex=0x10"
      result = IALParser.parse(source)
      expect(result[:flag]).to be true
      expect(result[:count]).to eq(42)
      expect(result[:pi]).to eq(3.14)
      expect(result[:hex]).to eq(16)
    end

    it "выбрасывает ошибку на неизвестные параметры при строгом режиме" do
      source = "???invalid"
      expect { IALParser.parse(source, strict: true) }.to raise_error(IALParser::UnknownParameterType)
    end

    it "сохраняет кавычки для значений при опции preserve_quotes" do
      source = "title='quoted'"
      result = IALParser.parse(source, preserve_quotes: true)
      expect(result[:title]).to eq("'quoted'")
      expect(result[:_quotes][:title]).to eq("'")
    end

  end

end