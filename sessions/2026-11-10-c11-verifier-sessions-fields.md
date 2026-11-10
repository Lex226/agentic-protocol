---
date: 2026-11-10
task: c11-verifier-sessions-fields
refs: "#20"
author: Cursor
---

# C11: verifier знает sessions_count, sessions_paths и секцию sessions

## Задача / ветка / commit

- Issue #20, `Refs #20`. Тип `code`. Карточка подтверждена владельцем: (a) ❌ в «Claimed but missing» при `sessions_count: 0`; (b) пакет без этих полей — не hard stop, в fingerprint `<отсутствует в пакете>` и ⚠️ «пакет старого сборщика»; (c) семь полей в порядке сборщика, строка скоупа вне fingerprint.
- Ветка `feat/c11-verifier-sessions-fields` от `origin/main` `d7f0a9356c024abf6cab01a1ca8a08de0d317dc7`. Blob `.cursor/agents/verifier.md` на этой базе — `5dca1a222ea5052ad77525e5e4004341e4703afb`.
- Метки #20: `enhancement`, `priority:medium`, `stage:in-progress`.
- `AGENTS.md` в репозитории нет.
- Этот текст входит в commit ветки. Полный SHA — в handoff.

## Сделано

`.cursor/agents/verifier.md`, «Required input»: в список пакета добавлены `sessions_count`, `sessions_paths` и секция `sessions`.

Шаблон Input fingerprint содержит семь полей в порядке вывода `scripts/verify/collect-verifier-pack.ps1`: `branch` (строка 199), `origin_main_sha` (200), `name_status_count` (202), `has_unstaged_changes` (203), `diff_mode` (204), `sessions_count` (205), `sessions_paths` (206). Строка скоупа (201) в шаблон не входит.

Одна фраза: `sessions_paths` повторяется как в пакете (`(none)` или пути через `, `).

При `sessions_count: 0` отчёт ставит ❌ в «Claimed but missing». Если в пакете нет ни `sessions_count`, ни `sessions_paths`, hard stop не ставится: оба поля в fingerprint пишутся как `<отсутствует в пакете>`, в «Out of scope» ставится ⚠️ `пакет старого сборщика`. Тексты hard stop `нет входных данных` и `нет скоупа` и запрет git для субагента не менялись.

`CHANGELOG.md`, `## [Unreleased]`, первая строка: `C11 — verifier: поля sessions_count и sessions_paths, секция sessions, Issue #20.` Строки C10 и C12 ниже не менялись.

`scripts/verify/collect-verifier-pack.ps1` не менялся. При `sessions_count` 0 сборщик по-прежнему печатает `sessions_paths: (none)` (строка 172) и тело секции `## sessions` (строка 214) равное `снимок сессии не найден` (строка 175).

## Решения

❌ при sessions_count 0 корректен, потому что снимок по cycle.md создаётся до verifier (шаг 3 → шаг 5).

Варианты тела секции `файл удалён в рабочем дереве` и warning о размере секции в C11 не обрабатываются.

## Проверки

Среда: Windows PowerShell 5.1.20348.4294.

| Проверка | Результат |
|---|---|
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify/tests/test-verifier-pack.ps1` | exit 0. `RESULT: 16 passed / 0 failed (total 16)` |
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/hooks/tests/run-guard-tests.ps1` | exit 0. `RESULT: 57 passed / 0 failed (total 57)` |
| pwsh 7 | не запущено: pwsh не найден |
| `git diff --check` | exit 0. Предупреждение Git: LF будет заменён на CRLF при следующем касании `.cursor/agents/verifier.md` |
| `git diff --cached --check` до абзаца verifier | exit 0. То же предупреждение для `.cursor/agents/verifier.md` |
| `git diff --cached --stat` до абзаца verifier | 3 files changed, 82 insertions(+), 2 deletions(-). Слов автозакрытия Issue в staged diff нет |

### verifier (субагент)

Запущено. Сбор `scripts/verify/collect-verifier-pack.ps1 -Issue 20` после staging, до этого абзаца: exit 0. Fingerprint пакета: `branch` `feat/c11-verifier-sessions-fields`, `origin_main_sha` `d7f0a9356c024abf6cab01a1ca8a08de0d317dc7`, `name_status_count` 3, `has_unstaged_changes` no, `diff_mode` full, `sessions_count` 1, `sessions_paths` `sessions/2026-11-10-c11-verifier-sessions-fields.md`.

Субагент вернул отчёт. Input fingerprint совпал со всеми семью полями, включая `sessions_count` и `sessions_paths`. Подтвердил правку Required input и шаблона, повтор `sessions_paths` как в пакете, правила для `sessions_count: 0` и для пакета старого сборщика, неизменность hard stop и запрета git, первую строку C11 в CHANGELOG и этот снимок. Чужих путей нет. Прогоны тестов и PR не засчитывал: в пакете были только записанные результаты, push ещё не был сделан. Отметил, что в снимке внутри пакета ещё нет результата этого запуска. Этот абзац дописан после прогона и есть та запись. Сверка родителем вместо субагента не оформлялась.

## Блокеры

Нет блокера публикации.

## Следующий шаг

Ревью Perplexity по handoff и merge проверенного SHA, если блокирующих замечаний нет. После merge по треку E следующая задача — C09 #16. Workflow `release` не запускается: `protocol/version.json` не менялся.

---
Perplexity 10.11.2026
- Закрыты #19 (merge 07ac7dd), #21 (merge a6f2c0e), #23 W02 (PR #29, HEAD 2d8b450,
  merge d7f0a93, приёмка issuecomment-6765566914). PR #27 закрыт без merge, заменён #28.
- Поправка к снимку C10: строка «C12: ветка docs/c12-perplexity-project-labels @ 527adf8,
  PR не создан» устарела. C12 смёржен PR #26 (merge a6f2c0e), PR #25 смёржен в 76ac75f.
- Трек P: C13 #24 — можно стартовать после merge W02. Трек E: C11 #20 → C09 #16.
- Решения владельца: internal-ревьюер допустим (merge тогда делает владелец; действует после C16);
  метки ставит Cursor по манифесту; apply-labels.ps1 переносится в agentic-protocol (C13).
- Кандидаты для conventions-auditor: дубль абзаца «Если субагент недоступен…» в protocol/cycle.md;
  .gitattributes LF/CRLF; единица длины в protocol/perplexity/README.md; метка accessibility;
  строка «Статус: Proposed» в шаблоне adr/ADR-0001-template.md.
---
