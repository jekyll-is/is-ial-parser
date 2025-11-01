# `is-ial-parser` — Универсальный парсер IAL для экосистемы Jekyll

[![Ruby](https://img.shields.io/badge/ruby-%203.0+-red.svg)](https://www.ruby-lang.org/)
[![Gem Version](https://badge.fury.io/rb/is-ial-parser.svg)](https://badge.fury.io/rb/is-ial-parser)
[![Tests](https://github.com/jekyll-is/is-ial-parser/actions/workflows/ruby.yml/badge.svg)](https://github.com/jekyll-is/is-ial-parser/actions/workflows/ruby.yml)
[![License: MIT](https://img.shields.io/badge/license-GPLv3-orange.svg)](LICENSE)

---

## Что это?

**`is-ial-parser`** — **единый, переиспользуемый парсер** для **Inline Attribute Lists (IAL)** в экосистеме Jekyll-плагинов.

Он **не зависит от Jekyll**, **не парсит Markdown**, а работает **только с сырой IAL-строкой** из Kramdown AST:

```ruby
[:ial, "{.term #def1 index:ООП @\"Глава 1\"}"]
```

→ превращает её в **структурированный хэш**:

```ruby
{
  attrs: { class: ["term"], id: "def1", "@": "Глава 1" },
  extensions: { index: "ООП" },
  meta: { "@": { quote: :double, interpolated: :ruby } }
}
```

---

## Зачем?

| Проблема | Решение |
|--------|--------|
| **Дублирование парсинга IAL** в `jekyll-span`, `jekyll-figure`, `jekyll-og-meta` | Один гем → один источник правды |
| **Ошибки на граничных случаях** (`@"..."`, `` `{{}}` ``, `ext:key=val`) | Тестируемый, строгий парсер |
| **Невозможность расширения** | `extensions:` → `fig:src=...`, `index:keyword` |
| **Отсутствие метаданных** | `meta:` → тип кавычек, интерполяция |

---

## Установка

```ruby
# Gemfile
gem 'is-ial-parser', '~> 1.0'
```

```bash
bundle install
```

---

## Использование

```ruby
require 'is_ial_parser'

ial = '{.term #def1 title="Hello" index:ООП @\"Chapter 1\" !draft fig:src="img.jpg"}'

result = IS::IALParser.parse(ial)

result.attrs        # → { class: ["term"], id: "def1", title: "Hello", "@": "Chapter 1", "!": "draft" }
result.extensions   # → { index: "ООП", fig: { src: "img.jpg" } }
result.meta         # → { title: { quote: :double, interpolated: :none }, "@": { quote: :double, interpolated: :ruby } }
result.warnings     # → []
```

---

## Поддерживаемые конструкции

| Тип | Синтаксис | Результат |
|-----|----------|---------|
| Классы | `.term .hl` | `class: ["term", "hl"]` |
| ID | `#def1` | `id: "def1"` |
| Атрибуты | `key=val`, `key="val"` | `"key": "val"` |
| Спецсимволы | `@"Chapter"`, `!draft`, `$100` | `"@": "Chapter"`, `"!": "draft"` |
| Расширения | `index:ООП`, `fig:src=img.jpg` | `extensions: { index: "ООП", fig: { src: "img.jpg" } }` |
| Liquid | ``key=`{{ var }}` `` | `meta: { interpolated: :liquid }` |
| Ruby | `key="#{expr}"` | `meta: { interpolated: :ruby }` |

---

## Конфигурация

```ruby
IS::IALParser.configure do |config|
  config.strict = true                    # Ошибки при дубликатах, пробелах
  config.allow_unquoted_values = false    # Запретить `key=val` без кавычек
  config.special_prefixes = ["@", "!", "$"] # Добавлять/убирать спецсимволы
end
```

Или при вызове:

```ruby
IS::IALParser.parse(ial, strict: true)
```

---

## Интеграция с Jekyll-плагинами

```ruby
# В jekyll-span, jekyll-figure и др.
Jekyll::Hooks.register [:pages, :documents], :pre_render do |doc|
  tree = doc.instance_variable_get(:@kramdown_tree) or next

  tree.elements.each do |node|
    next unless node.type == :ial
    raw_ial = node.value

    parsed = IS::IALParser.parse(raw_ial)
    # → используем parsed.attrs, parsed.extensions
  end
end
```

---

## Структура результата

```ruby
{
  attrs:       Hash,      # Стандартные атрибуты (class, id, data-*, etc.)
  extensions:  Hash,      # Расширения: index:, fig:, etc.
  meta:        Hash,      # Метаданные: кавычки, интерполяция
  warnings:    Array      # Только в strict: false
}
```

---

## Тестирование

- **Minitest** + **100% покрытие**
- **Фикстуры**: `test/fixtures/*.ial` → ожидаемый JSON
- **CI**: Ruby 3.0–3.3

```bash
rake test
```

---

## Roadmap

| Версия | Задача |
|-------|--------|
| **v0.1** | Базовый парсер: классы, ID, атрибуты |
| **v1.0** | Полная поддержка `ext:`, спецсимволов, `meta`, `strict` |
| **v1.1** | Глобальная конфигурация |
| **v2.0** | Опциональная интерполяция (Ruby/Liquid) с контекстом |

---

## Совместимость

- **Ruby ≥ 3.0**
- **Kramdown ≥ 2.3**
- **Jekyll ≥ 4.0** (через плагины)
- **GitHub Pages** — через Actions

---

## Лицензия

[MIT License](LICENSE)

<!--
---

## Авторы

**Jekyll-IS Team**  
`team@jekyll.is` | [jekyll.is](https://jekyll.is)
-->
