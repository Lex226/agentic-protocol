---
date: 2026-11-19
task: c37-perplexity-space-template
refs: "#64"
author: Cursor
---

# C37: обобщённый шаблон Space

## Задача / ветка / commit

- Issue #64, `Refs #64`. Тип `docs-only`. Карточка со СТОПом: скоуп Issue был предложением, исключение docs-only из `protocol/cycle.md` не применялось. Ответ владельца 19.11.2026: «да, с правками».
- Ветка `c37-perplexity-space-template` от `origin/main` `a49b110c37c0ed864a2ab71980026a833bc8a724`. Перед созданием ветки дерево клона было чистым. `git fetch origin`. `git ls-remote --heads origin c37-perplexity-space-template` был пуст. Blob `protocol/perplexity/project.md` совпал: `76c145f7c16817e58120163a96587f334362add0`. `git switch -c` поставил upstream на `origin/main`; затем `git branch --unset-upstream`.
- Работа в клоне `../agentic-protocol-c37`, одно окно Cursor. Основной checkout не менялся: там #62 C35, ветка `c35-engine-self-contained`.
- `AGENTS.md` в репозитории нет.
- Этот текст входит в commit ветки. Полный SHA — в handoff.

## Сделано

`protocol/perplexity/project.md`. Заголовок: `# Режим работы: agentic-protocol`. Правило дрейфа сохранено, путь источника: `<owner>/agentic-protocol`. Раздел «Источник и репозитории» больше не называет `1c-document-collection`, `github-playbook`, ADR-0003 и ADR-0005. Сразу после него — раздел «Персонально (заполняет владелец)» с плейсхолдерами `<consumer-repo>` и `<standards-repo>`. Заголовок ролей: `## Роли (protocol/roles.md)`. «Владелец (Lex226)» заменён на «Владелец». Строка стандарта меток: `<standards-repo> standards/labels.json`. Типы запросов A–F, «Неизменные правила» и «Формат ответов» по смыслу те же; в этих разделах сменилось только имя репозитория стандарта меток.

`protocol/perplexity/README.md`, только строка 3. `Lex226/agentic-protocol` заменён на `<owner>/agentic-protocol`. «экосистема Lex226» заменена на `agentic-protocol`, цитата Space стала «GitHub - agentic-protocol». Остальной текст README не менялся.

`CHANGELOG.md` не менялся.

## Решения

Ответ владельца 19.11.2026.

- B1: (b). Раздел «## Персонально (заполняет владелец)» — текст карточки, сразу после «Источник и репозитории». Вставка в Space = шаблон + заполненный блок.
- B2: плейсхолдеры `<owner>`, `<consumer-repo>`, `<standards-repo>`. Правило дрейфа: `<owner>/agentic-protocol`.
- B3: `CHANGELOG.md` не менять.
- Заголовок `project.md`: `# Режим работы: agentic-protocol`. Формулировка «шаблон Space» отклонена: текст вставляется в Space как есть.
- Расширение скоупа: `protocol/perplexity/README.md`, только вхождения шаблона A. Исключение строки README снято. Повторный поиск по `protocol/perplexity/` должен быть пуст, кроме плейсхолдеров. Плейсхолдеры шаблон не задевают, вывод пустой.

Параллельно с #62 C35, отдельный клон, решение владельца 19.11.2026. Merge этого PR — после C35. После merge владелец вставляет текст в Space. Клон не удалять до merge.

Очередь: #62 C35 → #63 C36 → #64 C37 → #31 C17 → #44 C25 → #45 C26 → #46 C27 → #42 C23 → #48 C29 → #49 C16 → #50 C30. Волна 2: C36 в основном checkout, C17 в клоне, merge C17 после C36.

## Проверки

Среда: Windows PowerShell 5.1. Клон `../agentic-protocol-c37`.

| Проверка | Результат |
|---|---|
| `rg -n "ADR-000[3-9]\|1c-document-collection\|github-playbook\|Lex226" protocol/perplexity/` | совпадений нет |
| длина `project.md` | `[System.IO.File]::ReadAllText`: 5909 символов с CR, 5827 без CR. Лимит Space 8000. Для вставки берётся длина без CR: 5827 |
| `git diff --cached --check` | exit 0, вывод пустой |
| `git diff --cached --stat` | 3 files changed, 70 insertions(+), 8 deletions(-): `protocol/perplexity/project.md`, `protocol/perplexity/README.md`, этот снимок |
| `git diff --cached -- protocol/perplexity/project.md` | имена, ADR и блок B1; типы A–F не переписаны |
| закрывающие ключи Issue и секреты в индексе | совпадений нет |

### verifier (субагент)

Запущено. Сбор `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify/collect-verifier-pack.ps1 -Issue 64` после staging, до этого абзаца: exit 0. Fingerprint пакета: `branch` `c37-perplexity-space-template`, `origin_main_sha` `a49b110c37c0ed864a2ab71980026a833bc8a724`, `name_status_count` 3, `has_unstaged_changes` no, `diff_mode` full, `sessions_count` 1, `sessions_paths` `sessions/2026-11-19-c37-perplexity-space-template.md`. `git diff --cached --stat` до этого абзаца: 3 files changed, 70 insertions(+), 8 deletions(-).

Субагент вернул отчёт. Input fingerprint совпал со всеми семью полями. Подтвердил шаблон `project.md`, строку 3 `README.md` как расширение скоупа, снимок с frontmatter, отсутствие `CHANGELOG.md`, три пути, типы A–F без переписывания смысла. Claimed but missing: нет. Out of scope: нет. Git субагент не запускал. дописано после прогона.

## Блокеры

Нет блокера публикации. Хвост: находки conventions-auditor в `protocol/perplexity/**` (поиск «персональн», правила правки заголовка и тела Issue) не исправлялись. Слово «Персонально» в новом разделе — текст, утверждённый владельцем. Строки про «персональную инструкцию» в типах запросов и формате ответов оставлены.

## Следующий шаг

Ревью Perplexity по handoff и merge проверенного SHA, если блокирующих замечаний нет. Issue #64 этим merge не закрывается. Merge — после C35. После merge владелец вставляет текст в Space: шаблон и заполненный персональный блок. Клон `../agentic-protocol-c37` остаётся до merge.
