---
date: 2026-11-10
task: c13-labels-apply-script
refs: "#24"
author: Cursor
---

# C13: apply-labels.ps1 в движке, аддитивный накат меток

## Задача / ветка / commit

- Issue #24, `Refs #24`. Тип `code`. Карточка со СТОПом подтверждена владельцем: «да». Шесть пунктов сверки Perplexity входят в реализацию.
- Ветка `feat/c13-labels-apply-script` от `origin/main` `07abaf27556889cc2c144fba04a593129a101a8a`. Blob `protocol/roles.md` на этой базе — `145b4e21c6c37d5cbc9e33626757d96726ef7f41`.
- Перед правками: `git fetch origin`. `origin/main` остался `07abaf27556889cc2c144fba04a593129a101a8a`. Ветка заново не создавалась. Конфликта CHANGELOG с C17 не было.
- Исходник `Lex226/github-playbook` `scripts/apply-labels.ps1`: коммит `eeffb66e9669e933dab0f1ea816a59d802f3055a`, blob `fa01bdf2e597b404bfd221d1daa97c71c5437fea` (короткий `fa01bdf` совпал).
- Метки #24: `enhancement`, `priority:medium`, `stage:in-progress`. Метка `stage:*` одна. `stage:intake` снята.
- `AGENTS.md` в репозитории нет. Корневой `PROVENANCE.md` уже был; отдельный `scripts/labels/PROVENANCE.md` не создавался.
- Этот текст входит в commit ветки. Полный SHA — в handoff.

## Сделано

`protocol/roles.md`, абзац в конце файла. Cursor накатывает метки только в репозиторий согласованной задачи, через `scripts/labels/apply-labels.ps1`. Набор — `standards/labels.json` из `labels.source` на полном SHA `labels.ref` (до манифеста C14 — SHA из Issue или брифа). Только создать отсутствующие и обновить цвет или описание. Удаление не входит. Других прав нет.

`scripts/labels/apply-labels.ps1`. Перенос blob `fa01bdf2e597b404bfd221d1daa97c71c5437fea`. `-Repo` остаётся. `-LabelsRef` обязателен, без значения по умолчанию, только `^[0-9a-f]{40}$`. Набор читается из `Lex226/github-playbook` `standards/labels.json` на этом SHA; если файла нет, выход ненулевой. `-WhatIf` — собственный `[switch]`, без `CmdletBinding` и без `ShouldProcess`. В WhatIf только чтение: по каждой метке набора строка «создать», «обновить» или «без изменений». `-RemoveExtra` и цикл удаления сняты. `-LabelsFile` не перенесён. Содержимое `contents` декодируется из base64 в UTF-8. `null` и `""` в description равны. При 200 метках печатается предупреждение. Ошибка `gh` пишется через `[Console]::Error`, не через `Write-Error`. Файл — UTF-8 с BOM, Windows PowerShell 5.1.

`scripts/labels/tests/test-apply-labels.ps1`. Фиктивный `gh.exe` собирается `csc.exe`, как в `scripts/verify/tests/test-verifier-pack.ps1`.

`PROVENANCE.md`. Новый раздел «C13: scripts/labels/apply-labels.ps1»: источник, коммит, blob, перечень изменений. Разделы C01 не менялись.

`README.md`, «Состав»: строка `scripts/labels/`.

`CHANGELOG.md`, `## [Unreleased]`, первая строка: `C13 — scripts/labels/apply-labels.ps1: аддитивный накат меток, -WhatIf, -LabelsRef; разрешение в roles.md, Issue #24.`

## Решения

`-WhatIf` сделан собственным `[switch]` в `param()` без `CmdletBinding`. `ShouldProcess` не используется. В этом режиме скрипт читает набор и список меток репозитория и не вызывает POST, PATCH и DELETE.

`-LabelsFile` исходника не перенесён: после переноса относительный путь смотрел бы мимо набора, а `standards/labels.json` в движок не копируется. Источник набора в скрипте — `Lex226/github-playbook`, SHA задаёт `-LabelsRef`.

Кандидаты conventions-auditor из блока Perplexity в конце снимка не правились. `guard-git.ps1` и `.cursor/hooks.json` не менялись: прогон `-WhatIf` на `Lex226/agentic-protocol` завершился, вызов `gh` не был остановлен guard.

## Проверки

Среда: Windows PowerShell 5.1.20348.4294.

| Проверка | Результат |
|---|---|
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/labels/tests/test-apply-labels.ps1` | exit 0. `RESULT: 12 passed / 0 failed (total 12)` |
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/hooks/tests/run-guard-tests.ps1` | exit 0. `RESULT: 57 passed / 0 failed (total 57)` |
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify/tests/test-verifier-pack.ps1` | exit 0. `RESULT: 16 passed / 0 failed (total 16)` |
| pwsh 7 | не запущено: pwsh не найден |
| `-WhatIf` на `Lex226/agentic-protocol` | exit 0. `-LabelsRef` `eeffb66e9669e933dab0f1ea816a59d802f3055a` (main playbook на момент прогона). Создать: 0. Полный вывод ниже |
| `git diff --cached origin/main -- protocol/roles.md` | только абзац о метках. Вывод ниже |
| `git diff --cached --check` | exit 0, вывода нет. При `git add` `PROVENANCE.md` Git предупредил: LF будет заменён на CRLF при следующем касании |
| `git diff --cached --stat` до абзаца verifier | 7 files changed, 890 insertions(+) |

Полный вывод `-WhatIf`:

```
Репозиторий: Lex226/agentic-protocol
Набор: Lex226/github-playbook standards/labels.json @ eeffb66e9669e933dab0f1ea816a59d802f3055a
Режим: WhatIf
без изменений: priority:high
без изменений: priority:medium
без изменений: priority:low
без изменений: stage:intake
без изменений: stage:discovery
без изменений: stage:in-progress
без изменений: stage:validation
без изменений: stage:release
без изменений: stage:blocked
без изменений: snapshot
без изменений: adr
без изменений: article
без изменений: audit-finding
без изменений: bug
без изменений: documentation
без изменений: duplicate
без изменений: enhancement
без изменений: good first issue
без изменений: help wanted
без изменений: invalid
без изменений: question
без изменений: wontfix
Итог: создать 0, обновить 0, без изменений 22.
```

`git diff --cached origin/main -- protocol/roles.md`:

```
diff --git a/protocol/roles.md b/protocol/roles.md
index 145b4e2..ac98c54 100644
--- a/protocol/roles.md
+++ b/protocol/roles.md
@@ -17,3 +17,5 @@
 Perplexity закрывает Issue (state_reason completed) только по прямому поручению владельца и только после комментария о приёмке со ссылкой на merge commit. Merge ≠ приёмка ≠ закрытие Issue.

 Закрытие PR без merge — только по прямому поручению владельца, после комментария с причиной; ветку не удалять.
+
+Cursor накатывает метки только в репозиторий согласованной задачи, через `scripts/labels/apply-labels.ps1`, набор — `standards/labels.json` из `labels.source` на полном SHA `labels.ref` (до манифеста C14 — SHA из Issue/брифа). Только создать отсутствующие и обновить цвет/описание; удаление не входит. Других прав нет.
```

### verifier (субагент)

Запущено. Сбор `scripts/verify/collect-verifier-pack.ps1 -Issue 24` после staging, до этого абзаца: exit 0. Fingerprint пакета: `branch` `feat/c13-labels-apply-script`, `origin_main_sha` `07abaf27556889cc2c144fba04a593129a101a8a`, `name_status_count` 7, `has_unstaged_changes` no, `diff_mode` full, `sessions_count` 1, `sessions_paths` `sessions/2026-11-10-c13-labels-apply-script.md`.

Субагент вернул отчёт. Input fingerprint совпал со всеми семью полями. Подтвердил абзац в `protocol/roles.md`, скрипт (`-LabelsRef`, `-WhatIf` без `CmdletBinding`, без удаления, base64 в UTF-8, `null` и пустое описание, предупреждение при 200 метках, ошибка `gh` через `[Console]::Error`), тесты на фиктивном `gh`, раздел C13 в `PROVENANCE.md` без правки разделов C01, строку `scripts/labels/` в README, первую строку C13 в CHANGELOG и этот снимок. Чужих путей нет. Прогоны тестов и PR не засчитывал: в пакете были только записанные результаты, push ещё не был сделан. Отметил, что в снимке внутри пакета ещё нет результата этого запуска. Этот абзац дописан после прогона и есть та запись. Сверка родителем вместо субагента не оформлялась.

## Блокеры

Нет блокера публикации.

## Следующий шаг

Ревью Perplexity по handoff и merge проверенного SHA, если блокирующих замечаний нет. После merge C13 — отдельный Issue в `Lex226/github-playbook`: deprecated для `scripts/apply-labels.ps1` и правка Правила 5. Трек E: C17 #31.

---
Perplexity 10.11.2026
- Закрыт #16 C09 (PR #32, HEAD e029660, merge 07abaf2, приёмка issuecomment-6767097650).
- Ранее закрыты #20 C11 (merge 64f6e2e) и #23 W02 (merge d7f0a93).
- Трек P: C13 #24 (этот). Трек E: C17 #31 (хвосты verifier после C11).
- После merge C13: отдельный Issue в github-playbook — deprecated для scripts/apply-labels.ps1 и правка Правила 5.
- Кандидаты для conventions-auditor: дубль абзаца «Если субагент недоступен…» в protocol/cycle.md;
  .gitattributes LF/CRLF; единица длины в protocol/perplexity/README.md; метка accessibility;
  «Статус: Proposed» в adr/ADR-0001-template.md.
---
