---
date: 2026-11-19
task: c39-precedence-constitution
refs: "#66"
author: Cursor
---

# C39: precedence.md без внешнего репозитория

## Задача / ветка / commit

- Issue #66, `Refs #66`. Тип `code`. Карточка со СТОПом; ответ владельца 19.11.2026: да, с правками A1 и A3.
- Ветка `c39-precedence-constitution` от `origin/main` `231a7ca37aa5e5cbc958a1ab8212eee0d0501503` (merge PR #72, C36). Перед созданием ветки дерево основного checkout было чистым (ветка `c36-labels-source-param`). `git fetch origin`. `git ls-remote --heads origin c39-precedence-constitution` был пуст. Blob `protocol/precedence.md` совпал: `9bb0efcdcd04ae5d56ef4656fb1a4101ddc64f2a`. `git switch -c` поставил upstream на `origin/main`; затем `git branch --unset-upstream`.
- Работа в основном checkout. Параллельных задач этой волны нет (S1, волна 3).
- `AGENTS.md` в репозитории нет.
- Этот текст входит в commit ветки. Полный SHA — в handoff.

## Сделано

`protocol/precedence.md`. Ссылка на репозиторий конституции снята. Строка классов называет Guardrails, Процесс, Предмет и говорит, что конституция владельца подключается через AGENTS.md потребителя и только ужесточает. Раздел Guardrails начинается с `protocol/` и подключённой конституции владельца (только ужесточения); запреты force-push, прямого push в main, merge только проверенного SHA и «Cursor не выполняет merge» сохранены. Номера Правил 10 и 11 и «уровень 1» сняты. Текст запрета секретов и персональных данных, «политика данных и ссылка на решение владельца», «явное исключение вместо тихого дрейфа» и «Других ослаблений Guardrails через AGENTS.md нет» оставлены. В «Конфликт классов» остаётся «Исключение явное.» Разделы «Процесс» и «Предмет» не менялись.

`CHANGELOG.md`, `## [Unreleased]`, первая запись: `C39: precedence.md без ссылки на внешний репозиторий; конституция владельца только ужесточает (Refs #66).` Строка C35 не менялась. `changelog.d/` нет: фрагменты вводит #65 C38.

## Решения

Ответ владельца на карточку 19.11.2026: да, с правками.

- A1. Строка классов: «Три класса: Guardrails, Процесс, Предмет. Конституция владельца подключается через AGENTS.md потребителя и только ужесточает; ослабить Guardrails или protocol/ она не может.»
- A2. (a). Номера Правил 10 и 11 и «уровень 1» сняты в абзаце Guardrails и в «Конфликт классов». Запреты и оговорка про явное исключение в AGENTS.md остаются текстом.
- A3. Строка Guardrails: «`protocol/` и подключённая конституция владельца (только ужесточения). Без force-push и прямого push в main. Merge только проверенного SHA. Cursor не выполняет merge.» Слово «Конституция» в кавычках как имя класса не используется.
- A4. Не править. `protocol/perplexity/project.md:11` (`<standards-repo> — конституция: standards/00-constitution.md`) — хвост для C38/conventions-auditor.

## Проверки

Среда: Windows PowerShell 5.1. Основной checkout.

| Проверка | Результат |
|---|---|
| `rg -n "github-playbook\|Lex226/" protocol/precedence.md` | пусто, exit 1 |
| `rg -n "Lex226/\|github-playbook" scripts/ protocol/ --glob "!protocol/perplexity/**"` | пусто, exit 1 |
| `rg -n "Конституц\|конституц" protocol/precedence.md` | два вхождения, оба «конституция владельца»; см. ниже |
| `rg -n "Правило 1[01]\|уровень 1" protocol/precedence.md` | пусто, exit 1 |
| `rg -n "Конституц\|конституц\|Правило 1[01]\|github-playbook\|Lex226/" protocol/ .cursor/ README.md templates/` | `templates/` каталога нет (rg exit 2). `.cursor/` и `README.md` — совпадений нет. Остаток: `precedence.md:3`, `precedence.md:7`, `protocol/perplexity/project.md:11` |
| `git diff --cached --check` | exit 0, вывод пустой |
| `git diff --cached --stat` | 3 files changed, 64 insertions(+), 4 deletions(-) |

`protocol/precedence.md:3` — «Конституция владельца» и «только ужесточает» в той же фразе. `protocol/precedence.md:7` — «конституция владельца» рядом с «только ужесточения» (формулировка A3).

Поиск по индексу на закрывающие ключи Issue и секреты: совпадений нет.

### verifier (субагент)

Запущено. Сбор `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify/collect-verifier-pack.ps1 -Issue 66` после staging, до этого абзаца: exit 0. Fingerprint пакета: `branch` `c39-precedence-constitution`, `origin_main_sha` `231a7ca37aa5e5cbc958a1ab8212eee0d0501503`, `name_status_count` 3, `has_unstaged_changes` no, `diff_mode` full, `sessions_count` 1, `sessions_paths` `sessions/2026-11-19-c39-precedence-constitution.md`. `git diff --cached --stat` до этого абзаца: 3 files changed, 64 insertions(+), 4 deletions(-).

Субагент вернул отчёт. Input fingerprint совпал со всеми семью полями. Подтвердил три пути: формулировки A1 и A3 в `protocol/precedence.md`, снятие номеров Правил 10/11 и «уровень 1» при сохранённых запретах, строка C39 в `## [Unreleased]`, снимок с frontmatter. `protocol/perplexity/project.md` в индексе нет. Claimed but missing: нет. Out of scope: нет. Git субагент не запускал. дописано после прогона.

## Блокеры

Нет блокера публикации.

Хвост: `protocol/perplexity/project.md:11` для C38/conventions-auditor. `adr/ADR-0002` не менялся. Строка C35 в `## [Unreleased]` не менялась.

## Следующий шаг

Ревью Perplexity по handoff и merge проверенного SHA, если блокирующих замечаний нет. Issue #66 этим merge не закрывается. После merge очередь: #65 C38 (волна 4, S2).
