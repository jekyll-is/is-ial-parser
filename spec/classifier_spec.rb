# spec/classifier_spec.rb
# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe IALParser::Classifier do
  Token = Struct.new(:raw, :quoted?, :quote_type, keyword_init: true)

  def classify(raw, quoted: false, quote_type: nil, special_prefixes: ['@', '!'])
    token = Token.new(raw: raw, quoted?: quoted, quote_type: quote_type)
    described_class.classify(token, special_prefixes: special_prefixes)
  end

  describe ".classify" do
    context "спец-префиксы" do
      it "обрабатывает @" do
        ct = classify('@"Chapter 1"', quoted: true, quote_type: :double)
        expect(ct.type).to eq(:special)
        expect(ct.key).to eq("@")
        expect(ct.value).to eq("Chapter 1")
        expect(ct.raw_key).to eq("@")
        expect(ct.raw_value).to eq("\"Chapter 1\"")  # ← без @
      end

      it "обрабатывает !draft" do
        ct = classify('!draft')
        expect(ct.type).to eq(:special)
        expect(ct.key).to eq("!")
        expect(ct.value).to eq("draft")
        expect(ct.raw_value).to eq("draft")  # ← без !
      end

      it "поддерживает кастомные префиксы" do
        ct = classify('%value', special_prefixes: ['%'])
        expect(ct.type).to eq(:special)
        expect(ct.key).to eq("%")
        expect(ct.raw_value).to eq("value")
      end

      it "игнорирует неизвестные префиксы" do
        ct = classify('$value')
        expect(ct.type).to eq(:attr)
        expect(ct.key).to eq("$value")
      end
    end

    context "классы" do
      it "обрабатывает .term" do
        ct = classify('.term')
        expect(ct.type).to eq(:class)
        expect(ct.value).to eq("term")
        expect(ct.raw_value).to eq("term")  # ← без .
      end

      it "снимает кавычки" do
        ct = classify('."my class"', quoted: true)
        expect(ct.value).to eq("my class")
        expect(ct.raw_value).to eq("\"my class\"")  # ← без .
      end
    end

    context "ID" do
      it "обрабатывает #def1" do
        ct = classify('#def1')
        expect(ct.type).to eq(:id)
        expect(ct.value).to eq("def1")
        expect(ct.raw_value).to eq("def1")  # ← без #
      end
    end

    context "расширения (ext:val)" do
      it "index:API" do
        ct = classify('index:API')
        expect(ct.type).to eq(:ext)
        expect(ct.key).to eq("index")
        expect(ct.value).to eq("API")
        expect(ct.raw_value).to eq("API")
      end

      it "abbr:API=REST → :ext" do
        ct = classify('abbr:API=REST')
        expect(ct.type).to eq(:ext)
        expect(ct.key).to eq("abbr")
        expect(ct.value).to eq("API=REST")
        expect(ct.raw_value).to eq("API=REST")
      end

      it "с кавычками" do
        ct = classify('title:"Hello World"', quoted: true)
        expect(ct.type).to eq(:ext)
        expect(ct.value).to eq("Hello World")
        expect(ct.raw_value).to eq("\"Hello World\"")
      end
    end

    context "атрибуты (key=value)" do
      it "count=42" do
        ct = classify('count=42')
        expect(ct.type).to eq(:attr)
        expect(ct.key).to eq("count")
        expect(ct.value).to eq("42")
      end

      it "title=\"Hi\"" do
        ct = classify('title="Hi"', quoted: true, quote_type: :double)
        expect(ct.value).to eq("Hi")
        expect(ct.raw_value).to eq("\"Hi\"")
      end

      it "пустое значение key=" do
        ct = classify('key=')
        expect(ct.value).to eq("")
      end

    end

    context "флаги" do
      it "hidden" do
        ct = classify('hidden')
        expect(ct.type).to eq(:attr)
        expect(ct.key).to eq("hidden")
        expect(ct.value).to be_nil
      end
    end

    context "граничные случаи" do
      it "=value (только значение)" do
        ct = classify('=value')
        expect(ct.type).to eq(:attr)
        expect(ct.key).to eq("")
        expect(ct.value).to eq("value")
      end

      it "key= (пустое значение)" do
        ct = classify('key=')
        expect(ct.value).to eq("")
      end

      it ":: (две двоеточия)" do
        ct = classify('::')
        expect(ct.type).to eq(:ext)
        expect(ct.key).to eq("")
        expect(ct.value).to eq(":")
        expect(ct.raw_value).to eq(":")
      end

      it "key==value" do
        ct = classify('key==value')
        expect(ct.key).to eq("key")
        expect(ct.value).to eq("=value")
      end
    end

    context "экранирование и кавычки" do
      it "title=\"Hi \\\"world\\\"\" — Classifier не unescape" do
        ct = classify('title="Hi \"world\""', quoted: true)
        expect(ct.value).to eq("Hi \\\"world\\\"")  # ← как после снятия кавычек
        expect(ct.raw_value).to eq("\"Hi \\\"world\\\"\"")
      end

      it "backtick s=`{{var}}`" do
        ct = classify('s=`{{var}}`', quoted: true, quote_type: :backtick)
        expect(ct.value).to eq("{{var}}")
        expect(ct.raw_value).to eq("`{{var}}`")
      end
    end
  end
end
