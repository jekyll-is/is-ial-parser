# lib/ial_parser/classifier.rb
# frozen_string_literal: true

require_relative 'tokenizer'

module IALParser
  # Классифицирует токены от Tokenizer.
  # Определяет тип, извлекает key/value, сохраняет оригинальные строки.
  # Не конвертирует типы, не валидирует — только структура.
  module Classifier
    # Структура результата: иммутабельна, с именованными аргументами
    ClassifiedToken = Struct.new(
      :type,        # :attr | :ext | :class | :id | :special
      :key,         # String | nil
      :value,       # String | nil (без внешних кавычек)
      :raw_key,     # String
      :raw_value,   # String | nil (с кавычками, как в токене)
      :token,       # Tokenizer::Token
      keyword_init: true
    )

    class << self
      # @param token [Tokenizer::Token]
      # @param special_prefixes [Array<String>]
      # @return [ClassifiedToken]
      def classify(token, special_prefixes: ['@', '!'])
        raw = token.raw
        quoted = token.quoted?

        # 1. Спец-префикс: @"value", !draft
        if raw[0] && special_prefixes.include?(raw[0])
          key = raw[0]
          value_str = raw[1..] || ''
          value = extract_value(value_str, quoted)
          return ClassifiedToken.new(
            type: :special,
            key: key,
            value: value,
            raw_key: key,
            raw_value: value_str,
            token: token
          )
        end

        # 2. Класс: .term
        if raw.start_with?('.')
          value_str = raw[1..] || ''
          value = extract_value(value_str, quoted)
          return ClassifiedToken.new(
            type: :class,
            value: value,
            raw_value: value_str,
            token: token
          )
        end

        # 3. ID: #def1
        if raw.start_with?('#')
          value_str = raw[1..] || ''
          value = extract_value(value_str, quoted)
          return ClassifiedToken.new(
            type: :id,
            value: value,
            raw_value: value_str,
            token: token
          )
        end

        # 4. Расширение: всё с :
        if raw.include?(':')
          key, value_str = raw.split(':', 2)
          value = extract_value(value_str, quoted)
          return ClassifiedToken.new(
            type: :ext,
            key: key,
            value: value,
            raw_key: key,
            raw_value: value_str,
            token: token
          )
        end

        # 5. Атрибут: key=value (только если нет :)
        if raw.include?('=')
          key, value_str = raw.split('=', 2)
          value = extract_value(value_str, quoted)
          return ClassifiedToken.new(
            type: :attr,
            key: key,
            value: value,
            raw_key: key,
            raw_value: value_str,
            token: token
          )
        end

        # 6. Флаг: hidden
        ClassifiedToken.new(
          type: :attr,
          key: raw,
          raw_key: raw,
          token: token
        )
      end

      private

      # Убирает внешние кавычки, если токен был в кавычках
      def extract_value(str, quoted)

        return str unless quoted && str && str.size >= 2

        quote = str[0]
        if str[-1] == quote && ['"', "'", '`'].include?(quote)
          # Исправление: снимаем кавычки, но НЕ unescape
          # Для `title="Hi \"world\""` → raw_value = "\"Hi \\\"world\\\"\""
          # → str = "\"Hi \\\"world\\\"\"" → str[1..-2] = "Hi \\\"world\\\""
          str[1..-2]
        else
          str
        end
      end
    end
  end
end