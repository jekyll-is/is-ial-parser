# is-ial-parser

**Универсальный парсер Inline Attribute Lists (IAL) для Kramdown и Jekyll-плагинов**  
*Версия 1.0 – концепция и реализация*  
*Лицензия: GNU GPLv3*  

---

## 1. Почему нужен отдельный парсер IAL?

* **Единый парсер для всех плагинов** – `jekyll-is-span`, `jekyll-is-index`, `jekyll-is-tocs` и др. используют одну и ту же логику разбора.  
* **Поддержка расширений** – `ext:val`, вложенные `ext:key=val`, спец-значения (`@"…"`, `!val`).  
* **Безопасность** – строгий режим (`strict: true`) и валидация на этапе парсинга.  
* **Независимость** – гем **не зависит** от Jekyll, работает в любых Ruby-проектах с Kramdown-AST.

---

## 2. Что парсит?

| Синтаксис | Пример | Результат (Ruby-hash) |
|-----------|--------|-----------------------|
| `.class` | `.term .hl` | `class: ["term", "hl"]` |
| `#id` | `#def1` | `id: "def1"` |
| `key=value` | `data-x=1` | `"data-x": "1"` |
| `key="value"` | `title="Hello world"` | `title: "Hello world"` |
| `ext:val` | `index:ООП` | `extensions: { index: "ООП" }` |
| `ext:key=val` | `abbr:API=Application Programming Interface` | `extensions: { abbr: { API: "Application Programming Interface" } }` |
| Флаг | `hidden` | `hidden: "true"` |
| Спец-значения | `@"Chapter 1"` | `"@": "Chapter 1"` |
| Спец-значения | `!draft` | `"!": "draft"` |

**Полный список спец-префиксов** (настраивается): `@`, `!`, `$`, `^`, `&`, `*`, `+`, `~`.

---

## 3. Формат возвращаемого хэша

```ruby
{
  attrs: {
    class: ["term"],
    id: "def1",
    title: "Hello #{name}",
    "@": "Chapter 1",
    "!": "draft"
  },
  extensions: {
    index: "ООП!#{page.section}",
    abbr: { API: "Application Programming Interface" }
  },
  meta: {
    title: { quote: :double, interpolated: :ruby },
    "abbr.API": { quote: :none, interpolated: :none },
    "@": { quote: :double, interpolated: :ruby }
  },
  warnings: []   # только в strict: false
}
```

*`meta`* хранит тип кавычек и тип интерполяции – **парсер не выполняет** интерполяцию, только помечает её.

---

## 4. Конфигурация (через `_config.yml` или `IALParser.parse(..., options)`)

```yaml
ial_parser:
  strict: false               # по умолчанию – совместимость с legacy
  special_prefixes: ["@", "!", "$", "^", "&", "*", "+", "~"]
  allow_unquoted_values: false
  enable_ruby_interpolation: false   # только плагин решает
  enable_liquid_interpolation: true
```

---

## 5. Пример использования

```ruby
require "ial_parser"

ial = '{.term #def1 @"ООП: инкапсуляция" index:ООП!#{page.section} abbr:API=Application Programming Interface}'
result = IALParser.parse(ial, strict: true)

pp result
# => { attrs: { class: ["term"], id: "def1", "@": "ООП: инкапсуляция" },
#      extensions: { index: "ООП!#{page.section}", abbr: { API: "Application Programming Interface" } },
#      meta: { "@": { quote: :double, interpolated: :ruby },
#              index: { quote: :double, interpolated: :ruby },
#              "abbr.API": { quote: :none, interpolated: :none } },
#      warnings: [] }
```

---

## 6. Интеграция с Kramdown-AST

```ruby
# В любом Jekyll-плагине
Jekyll::Hooks.register [:pages, :documents], :pre_render do |doc, payload|
  tree = doc.instance_variable_get(:@kramdown_tree) or next

  tree.traverse do |node|
    next unless node.type == :ial
    parsed = IALParser.parse(node.value, strict: true)
    # → используем parsed.attrs / parsed.extensions
  end
end
```

---

## 7. Тесты

* `test/fixtures/*.ial` – набор входных строк.  
* `test/parser_test.rb` – 100 % покрытие (RSpec).  
* Строгий режим проверяет дубли `#id` и неизвестные спец-префиксы (если не в `special_prefixes`).

---

## 8. Roadmap

| Версия | Задача |
|--------|--------|
| **v1.0** | Базовый парсинг + `meta` + `extensions` |
| **v1.1** | Поддержка `` `{{…}}` `` как `quote: :liquid` |
| **v1.2** | Глобальная конфигурация + `strict` режим |
| **v2.0** | Опциональная интерполяция через `context` (Ruby/Liquid) |

---

## 9. Лицензия

**GNU General Public License v3.0**  
См. файл [`LICENSE`](LICENSE) (GPLv3).  
*Код распространяется «как есть», без гарантий.*

---

## 10. Вклад

1. Форк → `feature/your-name`  
2. `bundle install && bundle exec rspec`  
3. Pull Request с описанием изменений.

---

**Готово к реализации v1.0.**  
Следующий шаг – написать `lib/ial_parser/parser.rb` и тесты.
