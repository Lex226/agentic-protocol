---
date: 2026-11-10
task: c09-task-start-step2-wrap
refs: "#16"
author: Cursor
---

# C09: перенос длинной строки шага 2 в task-start

## Задача / ветка / commit

- Issue #16, `Refs #16`. Тип `code`. Карточка подтверждена владельцем: «да». Уточнения без расширения скоупа: публикация только `git push -u origin HEAD` (голый `git push` не использовать: upstream ветки — `origin/main`); в снимок, кроме `--word-diff`, входит обычный `git diff --cached origin/main` по шагу 2.
- Ветка `chore/c09-task-start-step2-wrap` от `origin/main` `64f6e2efc9679b3c985a3798580074765f80624d`. Blob `.cursor/skills/task-start/SKILL.md` на этой базе — `12a7cd114eebd9f65a6bd01ee46fec924183ab11`.
- Метки #16: `enhancement`, `priority:low`, `stage:in-progress`. Метка `stage:*` одна. `stage:intake` снята.
- `AGENTS.md` в репозитории нет.
- Этот текст входит в commit ветки. Полный SHA — в handoff.

## Сделано

`.cursor/skills/task-start/SKILL.md`, шаг 2. Строка 31 разбита после `applies;`. Слова, знаки и порядок те же. Отступ продолжения — 3 пробела. Длины новых строк — 77 и 51. Строка `otherwise treat as СТОП and say so).` не менялась. Остальные шаги 0–9 не менялись.

`CHANGELOG.md`, `## [Unreleased]`, первая строка: `C09 — task-start: перенос длинной строки шага 2 без смены текста, Issue #16.` Строки C11, C10, C12, C08 и ниже не менялись.

## Решения

Перенос стоит после `applies;`: первая строка 77 символов, рядом с шириной соседних строк шагов 0–9. Пробел между `applies;` и `a` заменён переносом и отступом продолжения, как в уже перенесённых строках того же шага.

Кандидаты conventions-auditor не правились. Они перечислены в блоке Perplexity в конце снимка.

## Проверки

Среда: Windows PowerShell 5.1.20348.4294.

| Проверка | Результат |
|---|---|
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/hooks/tests/run-guard-tests.ps1` | exit 0. `RESULT: 57 passed / 0 failed (total 57)` |
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify/tests/test-verifier-pack.ps1` | exit 0. `RESULT: 16 passed / 0 failed (total 16)` |
| pwsh 7 | не запущено: pwsh не найден |
| `git diff --cached --word-diff origin/main -- .cursor/skills/task-start/SKILL.md` | маркеров `[-…-]{+…+}` нет. Вывод ниже |
| `git diff --cached origin/main -- .cursor/skills/task-start/SKILL.md` | перенос виден: одна длинная строка снята, две строки добавлены. Вывод ниже |
| `git diff --cached --check` | exit 0, до включения этого снимка |
| `git diff --cached --stat` | до включения этого снимка: 2 files changed, 3 insertions(+), 1 deletion(-). `.cursor/skills/task-start/SKILL.md`, `CHANGELOG.md` |
| метки #16 | `enhancement`, `priority:low`, `stage:in-progress` |

`git add` предупредил: LF будет заменён на CRLF при следующем касании `.cursor/skills/task-start/SKILL.md`. В индексе у этого файла `i/lf`.

### word-diff

```text
diff --git a/.cursor/skills/task-start/SKILL.md b/.cursor/skills/task-start/SKILL.md
index 12a7cd1..9f3d1f2 100644
--- a/.cursor/skills/task-start/SKILL.md
+++ b/.cursor/skills/task-start/SKILL.md
@@ -28,7 +28,8 @@ missing or contradicts AGENTS.md/ADR — STOP and list the gaps; do not guess.
   outside the brief's scope, report it as a tail, do not copy it.
2. **Task card.** Use skill `task-card`. If brief says `task-card: СТОП` —
   stop and wait for the owner's answer. If `продолжить` — print the card and
   go on (only when protocol/cycle.md section «Исключение docs-only» applies;
   a consumer AGENTS.md may only tighten that rule;
   otherwise treat as СТОП and say so).
3. **Edit** only the items under «Скоуп». An item that needs a new requirement
   is not edited: mark «требует решения владельца» and report it.
```

### обычный diff шага 2

```text
diff --git a/.cursor/skills/task-start/SKILL.md b/.cursor/skills/task-start/SKILL.md
index 12a7cd1..9f3d1f2 100644
--- a/.cursor/skills/task-start/SKILL.md
+++ b/.cursor/skills/task-start/SKILL.md
@@ -28,7 +28,8 @@ missing or contradicts AGENTS.md/ADR — STOP and list the gaps; do not guess.
    outside the brief's scope, report it as a tail, do not copy it.
 2. **Task card.** Use skill `task-card`. If brief says `task-card: СТОП` —
    stop and wait for the owner's answer. If `продолжить` — print the card and
-   go on (only when protocol/cycle.md section «Исключение docs-only» applies; a consumer AGENTS.md may only tighten that rule;
+   go on (only when protocol/cycle.md section «Исключение docs-only» applies;
+   a consumer AGENTS.md may only tighten that rule;
    otherwise treat as СТОП and say so).
 3. **Edit** only the items under «Скоуп». An item that needs a new requirement
    is not edited: mark «требует решения владельца» and report it.
```

### verifier (субагент)

Запущено. Сбор `scripts/verify/collect-verifier-pack.ps1 -Issue 16` после staging этого снимка, до этого абзаца: exit 0. Fingerprint пакета: `branch` `chore/c09-task-start-step2-wrap`, `origin_main_sha` `64f6e2efc9679b3c985a3798580074765f80624d`, `name_status_count` 3, `has_unstaged_changes` no, `diff_mode` full, `sessions_count` 1, `sessions_paths` `sessions/2026-11-10-c09-task-start-step2-wrap.md`.

`git diff --cached --stat` на этом staging: 3 files changed, 106 insertions(+), 1 deletion(-).

Субагент вернул отчёт. Input fingerprint совпал со всеми семью полями. Подтвердил три пути скоупа, перенос строки шага 2 после `applies;` без смены слов и знаков, первую строку C09 в CHANGELOG и оба diff в этом снимке. Чужих путей нет. PR с `Refs #16` и прогоны тестов не засчитывал: в пакете не было PR, а результаты тестов были только записью в снимке. Отметил, что в снимке внутри пакета ещё нет результата этого запуска. Этот абзац дописан после прогона и есть та запись. Сверка родителем вместо субагента не оформлялась.

## Блокеры

Нет блокера публикации.

## Следующий шаг

Ревью Perplexity по handoff и merge проверенного SHA, если блокирующих замечаний нет. После merge по треку E следующая задача — C17 #31. Трек P: C13 #24 можно стартовать. Workflow `release` не запускается: `protocol/version.json` не менялся.

---
Perplexity 10.11.2026
- Закрыты #20 C11 (PR #30, HEAD c2b8c46, merge 64f6e2e, приёмка issuecomment-6766291417)
  и #23 W02 (PR #29, merge d7f0a93, приёмка issuecomment-6765566914).
- Новый Issue #31 [C17]: хвосты C11 по verifier (hard stop 1 и 5 базовых полей, пакет с одним
  из sessions_*, «файл удалён в рабочем дереве», warning размера секции sessions).
  Метки enhancement, priority:low, stage:intake. Трек E: C09 #16 → C17 #31.
- Трек P: C13 #24 можно стартовать (W02 смёржен).
- Кандидаты для conventions-auditor: дубль абзаца «Если субагент недоступен…» в protocol/cycle.md;
  .gitattributes LF/CRLF; единица длины в protocol/perplexity/README.md; метка accessibility;
  «Статус: Proposed» в adr/ADR-0001-template.md.
---
