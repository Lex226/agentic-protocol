---
date: 2026-11-18
task: c31-perplexity-labels
refs: "#52"
author: Cursor
---

# C31: смена меток Issue/PR в разрешённых записях Perplexity

## Задача / ветка / commit

- Issue #52, `Refs #52`. Тип `code`. Карточка подтверждена владельцем. Исключение docs-only не применяется: меняется `protocol/roles.md`.
- Ветка `c31-perplexity-labels` от `origin/main` `343642031ec15d9461d81cb5c1ae573d9e9d8ebd` (merge PR #53, C24). Перед созданием ветки дерево было чистым. `git fetch origin`: `origin/main` совпал с ожидаемым SHA.
- `AGENTS.md` в репозитории нет. Прочитаны `protocol/roles.md`, `protocol/precedence.md`, `protocol/cycle.md`, `protocol/perplexity/project.md`, Issue #52, комментарий `issuecomment-6979670646`, `CHANGELOG.md` `[Unreleased]`, последний снимок `sessions/2026-11-18-c24-adr-0002-accepted.md`.
- Этот текст входит в commit ветки. Полный SHA — в handoff.

## Сделано

`protocol/roles.md`. После абзаца о закрытии PR без merge и перед абзацем C22 про `scripts/labels/apply-labels.ps1` добавлен абзац: Perplexity меняет метки существующего Issue/PR только по прямому поручению владельца или при create_issue; только метки, уже существующие в репо (проверка get_label). Создание, правка и удаление меток репозитория не входят. Текст C21/C22 и фраза «Других прав нет.» не менялись.

`protocol/perplexity/project.md`. В списке «Разрешено» добавлена смена меток существующего Issue/PR с теми же тремя условиями. Создание, правка и удаление меток репозитория не входят; указаны `scripts/labels/apply-labels.ps1` у Cursor и `protocol/roles.md`. Список «Запрещено» не менялся.

`CHANGELOG.md` `[Unreleased]`: запись C31 стоит над C22.

`sessions/2026-11-18-perplexity-c31.md` — дословный снимок из брифа, включая решение владельца по #44.

## Решения

Три условия в `protocol/roles.md` и в списке «Разрешено» совпадают по смыслу: прямое поручение владельца или `create_issue`; только метки, уже существующие в репо (проверка `get_label`); создание, правка и удаление меток репозитория не входят. В `project.md` третье условие дополнительно называет скрипт Cursor и `protocol/roles.md`.

`protocol/precedence.md`, раздел «Процесс»: «Ослабление — только изменением `protocol/` через Issue в agentic-protocol.» Это изменение `protocol/` по Issue #52. Список «Запрещено» и Guardrails не ослаблены. Противоречия с `protocol/precedence.md` нет.

## Проверки

Среда: Windows PowerShell 5.1.

| Проверка | Результат |
|---|---|
| `git diff --check` | exit 0, вывод пустой |
| `git diff --stat origin/main` до индексации снимков | 3 files changed, 4 insertions(+), 1 deletion(-): `CHANGELOG.md`, `protocol/perplexity/project.md`, `protocol/roles.md`. Неотслеживаемый `sessions/2026-11-18-perplexity-c31.md` в этот stat не входит |
| Сверка трёх условий | совпадают по смыслу в обоих файлах |
| `protocol/precedence.md` | строка раздела «Процесс» процитирована выше; противоречия нет |
| `rg -n -i "персональн" protocol/perplexity` | exit 0. Три прежние строки: `README.md:3`, `project.md:35`, `project.md:76`. Вне скоупа, не исправлялись |
| `git diff --cached --check` | exit 0, вывод пустой |
| `git diff --cached --name-status origin/main` | `M` `CHANGELOG.md`, `M` `protocol/perplexity/project.md`, `M` `protocol/roles.md`, `A` оба снимка |

### verifier (субагент)

Запущено. Сбор `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify/collect-verifier-pack.ps1 -Issue 52` после staging, до этого абзаца: exit 0. Fingerprint пакета: `branch` `c31-perplexity-labels`, `origin_main_sha` `343642031ec15d9461d81cb5c1ae573d9e9d8ebd`, `name_status_count` 5, `has_unstaged_changes` no, `diff_mode` full, `sessions_count` 2, `sessions_paths` `sessions/2026-11-18-c31-perplexity-labels.md, sessions/2026-11-18-perplexity-c31.md`. `git diff --cached --stat origin/main` до этого абзаца: 5 files changed, 64 insertions(+), 1 deletion(-).

Субагент вернул отчёт. Input fingerprint совпал со всеми семью полями. Подтвердил критерии карточки: три одинаковых по смыслу условия в `protocol/roles.md` и в списке «Разрешено», список «Запрещено» без изменений, запись C31 над C22, оба снимка, абзац в `roles.md` между закрытием PR без merge и абзацем C22. Claimed but missing: нет. Out of scope: нет. Git субагент не запускал. Этот абзац дописан после прогона. Сверка трёх условий и цитата `protocol/precedence.md` в разделе «Решения» — сверка родителем, отдельно от субагента.

## Блокеры

Нет блокера публикации. Хвост `rg "персональн"` — три прежние строки в `protocol/perplexity/**` («персональная инструкция»).

## Следующий шаг

Ревью Perplexity по handoff и merge проверенного SHA, если блокирующих замечаний нет. Issue #52 не закрывается этим merge. После merge владелец вставляет `protocol/perplexity/project.md` в Space.
