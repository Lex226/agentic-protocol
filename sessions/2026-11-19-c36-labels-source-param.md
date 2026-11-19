---
date: 2026-11-19
task: c36-labels-source-param
refs: "#63"
author: Cursor
---

# C36: источник набора меток — параметр

## Задача / ветка / commit

- Issue #63, `Refs #63`. Тип `code`. Карточка со СТОПом: вариант источника оставлен владельцу в теле #63.
- Ветка `c36-labels-source-param` от `origin/main` `a548ec7b6c7c48136ff99bbe2668b0cf60b9fb87` (merge PR #67, C37). Перед созданием ветки дерево основного checkout было чистым (ветка `c35-engine-self-contained`). `git fetch origin`. `git ls-remote --heads origin c36-labels-source-param` был пуст. Blob `scripts/labels/apply-labels.ps1` совпал: `c06768ef2e350a035800f3956bf7d5d3ed474b3e`. `git switch -c` поставил upstream на `origin/main`; затем `git branch --unset-upstream`.
- Работа в основном checkout. Параллельных задач этой волны нет.
- `AGENTS.md` в репозитории нет.
- Этот текст входит в commit ветки. Полный SHA — в handoff.

## Сделано

`scripts/labels/apply-labels.ps1`. Присваивание `$LabelsSource = 'Lex226/github-playbook'` снято. Источник набора — обязательный параметр `-LabelsSource` (owner/name), без значения по умолчанию. Проверка формата та же, что у `-Repo`: `^[^/\s]+/[^/\s]+$`. `-LabelsRef` по-прежнему обязателен, только `^[0-9a-f]{40}$`. Путь набора — `standards/labels.json`. `.SYNOPSIS`, `.PARAMETER` и сообщения не называют конкретный репозиторий. Строка «Набор:» печатает переданный `-LabelsSource`.

`scripts/labels/tests/test-apply-labels.ps1`. Расширение скоупа. Существующие вызовы передают `-LabelsSource fixture/source`. WhatIf-кейс проверяет эту строку в выводе и в пути `repos/fixture/source/contents/standards/labels.json`. Контракт скрипта требует `$LabelsSource` и запрещает присваивание `$LabelsSource =`. Новый кейс `missing-labels-source`: вызов без `-LabelsSource`, ненулевой exit, в тексте есть `LabelsSource`.

`protocol/roles.md`, последний абзац. Фраза про добавление в стандарт заменена на: «Добавление в стандарт — в репозитории `labels.source`.» Остальной абзац, включая «Других прав нет.», без изменений.

`PROVENANCE.md`, раздел C13. Строки происхождения (репозиторий, путь, коммит, blob) оставлены. Буллет про чтение набора обновлён: путь `standards/labels.json` на `-LabelsRef`, репозиторий набора — `-LabelsSource` (C36, #63), при переносе C13 репозиторий был зашит как источник импорта.

`CHANGELOG.md`, `## [Unreleased]`, первая запись: `C36: apply-labels — источник набора меток параметром (Refs #63).`

## Решения

Ответ на карточку 19.11.2026.

- Источник набора: обязательный параметр `-LabelsSource` (owner/name), без значения по умолчанию. Скрипт не читает `.agentic/config.json`. Поле `labels.source` по-прежнему задаёт #44 C25; этот параметр — вход, которым C25 сможет передать значение.
- Расширение скоупа: `scripts/labels/tests/test-apply-labels.ps1`.

Критерий поиска имён: дополнительное исключение `protocol/precedence.md` до merge #66 C39 (#63 issuecomment-7005416253). `changelog.d/` в этом PR нет: фрагменты вводит #65 C38, C36 идёт раньше и пишет в `## [Unreleased]`.

Очередь после этой задачи — волны из #65 issuecomment-7007409961. C37 уже в базе (PR #67).

| Волна | Основной checkout | Клон | Merge |
|---|---|---|---|
| 2 | #63 C36 | — | C36 |
| 3 | #66 C39 | — | C39 |
| 4 | #65 C38 (+ фрагменты) | — | C38 |
| 5 | #44 C25 | #31 C17 | C25 → C17 |
| 6 | #45 C26 | блоки #42 C23 (C40 → C41 → C42) | C26 → блоки C23 |
| 7 | #46 C27 | — | C27 |
| 8 | #48 C29 (runtime владельца → релиз, сборка фрагментов) | — | C29 |
| 9 | #49 C16 | #50 C30 (репо потребителей) | независимо |

## Проверки

Среда: Windows PowerShell 5.1. Основной checkout.

| Проверка | Результат |
|---|---|
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/labels/tests/test-apply-labels.ps1` | exit 0. `RESULT: 13 passed / 0 failed (total 13)` |
| `rg -n "Lex226/\|github-playbook" scripts/ protocol/ --glob "!protocol/perplexity/**"` | одно совпадение: `protocol/precedence.md:3` |
| запуск без `-LabelsSource` (`-Repo Lex226/agentic-protocol -LabelsRef eeffb66e9669e933dab0f1ea816a59d802f3055a`) | exit 1. `Cannot process command because of one or more missing mandatory parameters: LabelsSource.` |
| неполный SHA (`-LabelsRef eeffb66`, источник `Lex226/github-playbook`) | exit 1. `LabelsRef must match ^[0-9a-f]{40}$ (full lowercase SHA). Got: eeffb66` |
| `-WhatIf` на `Lex226/agentic-protocol`, `-LabelsSource Lex226/github-playbook`, `-LabelsRef eeffb66e9669e933dab0f1ea816a59d802f3055a` | exit 0. Режим WhatIf. 22 метки «без изменений», создать 0, обновить 0. Запросов POST/PATCH не было |
| `git diff --cached --check` | exit 0, вывод пустой |
| `git diff --cached --stat` | 6 files changed, 115 insertions(+), 17 deletions(-) |

WhatIf, строки набора: priority:high, priority:medium, priority:low, stage:intake, stage:discovery, stage:in-progress, stage:validation, stage:release, stage:blocked, snapshot, adr, article, audit-finding, bug, documentation, duplicate, enhancement, good first issue, help wanted, invalid, question, wontfix. Итог: создать 0, обновить 0, без изменений 22.

Поиск по индексу на закрывающие ключи Issue и секреты: совпадений нет.

### verifier (субагент)

Запущено. Сбор `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify/collect-verifier-pack.ps1 -Issue 63` после staging, до этого абзаца: exit 0. Fingerprint пакета: `branch` `c36-labels-source-param`, `origin_main_sha` `a548ec7b6c7c48136ff99bbe2668b0cf60b9fb87`, `name_status_count` 6, `has_unstaged_changes` no, `diff_mode` full, `sessions_count` 1, `sessions_paths` `sessions/2026-11-19-c36-labels-source-param.md`. `git diff --cached --stat` до этого абзаца: 6 files changed, 115 insertions(+), 17 deletions(-).

Субагент вернул отчёт. Input fingerprint совпал со всеми семью полями. Подтвердил шесть путей: параметр `-LabelsSource` в `apply-labels.ps1`, расширение тестов, последний абзац `protocol/roles.md`, буллет C13 в `PROVENANCE.md`, запись C36 в `## [Unreleased]`, снимок с frontmatter. Claimed but missing: нет. Out of scope: нет. Git субагент не запускал. дописано после прогона.

## Блокеры

Нет блокера публикации.

Хвосты: `protocol/precedence.md:3` до #66 C39. `adr/ADR-0002-universal-protocol.md` хранит историческое первое значение `labels.source` и в этот скоуп не входит. `README.md` не менялся: вхождений скрипта и имени репозитория стандарта там нет. Запись C35 в `## [Unreleased]` по-прежнему называет остаток #63 и #64; эта строка — текст C35, в C36 не переписывалась. Схема `.agentic/config.json` остаётся #44 C25.

## Следующий шаг

Ревью Perplexity по handoff и merge проверенного SHA, если блокирующих замечаний нет. Issue #63 этим merge не закрывается. После merge очередь: #66 C39 в основном checkout, затем #65 C38. Дальше волны из таблицы выше.
