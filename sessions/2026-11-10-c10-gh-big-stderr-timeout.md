---
date: 2026-11-10
task: c10-gh-big-stderr-timeout
refs: "#19"
author: Cursor
---

# C10: timeout github-origin-gh-big-stderr

## Задача / ветка / commit

- Issue #19, `Refs #19`. Карточка подтверждена владельцем с правками. Тип `code`.
- Ветка `fix/c10-gh-big-stderr-timeout` создана от `origin/main` `89953d3ecd7002be7e666c0c0bd1bba2f52ac982`.
- Пока шла диагностика, `origin/main` стал `76ac75f2886ed192f413f080221aa542adffe766` (merge PR #25, коммит C12 `527adf8`, файл `protocol/perplexity/project.md`). `git merge` для Cursor закрыт hook. Ветка осталась на `89953d3`. Этот файл C10 не меняет.
- Этот текст входит в commit ветки. Полный SHA — в handoff.
- `AGENTS.md` в репозитории нет.

## Сделано

`scripts/verify/tests/test-verifier-pack.ps1` не менялся. Условие `github-origin-gh-big-stderr` прежнее: режим `GH_SHIM_MODE=bigerr`, около 1 МиБ в stderr, ненулевой exit, строка лога shim, маркер `c10-shim-bigerr`, оба чтения потока завершены.

В `Get-IssueScopeText` чтение stdout/stderr процесса `gh` оставлено как было. Текст ошибки `gh` больше не передаётся в `Write-Error`: та же строка пишется через `[Console]::Error.WriteLine`, затем `exit 1`. Успешный разбор JSON не менялся.

В `README.md`, раздел «Ограничения», снят пункт про timeout этого кейса: после правки кейс проходит.

В `CHANGELOG.md`, `## [Unreleased]`: `C10 — ошибка gh с большим stderr больше не идёт через Write-Error, Issue #19.`

`collect-verifier-pack.ps1` остаётся в UTF-8 с BOM. Список полей fingerprint в скрипте не менялся.

## Решения

Зонд отделяет подтверждённое от предположения. Предположение о дедлоке на синхронном чтении stdout при большом stderr не подтвердилось: процесс `gh` дописывает stderr и завершается, а сборщик после этого ещё долго жив. Вариант «оба `ReadToEndAsync`, затем `WaitForExit`, затем `GetResult`» на чтении stderr `gh` не завис, поэтому чтение не переписывалось. `Task.Run` не использовался.

Подтверждённая задержка — `Write-Error` с текстом около 1 МиБ в Windows PowerShell 5.1. Тот же объём через `[Console]::Error` возвращается сразу, и кейс по-прежнему видит маркер в потоке ошибки.

Пункт README снят, а не переписан: после прогона ограничения с этим timeout больше нет.

## Проверки

Среда зонда и тестов: Windows PowerShell 5.1.20348.4294.

| Проверка | Результат |
|---|---|
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify/tests/test-verifier-pack.ps1` до правки | exit 1. `RESULT: 15 passed / 1 failed (total 16)`. Единственный FAIL: `github-origin-gh-big-stderr: timeout` |
| Тот же прогон после правки | exit 0. `RESULT: 16 passed / 0 failed (total 16)`. `github-origin-gh-big-stderr` — PASS |
| pwsh 7 | не запущено: `where.exe pwsh` не нашёл `pwsh` |
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/hooks/tests/run-guard-tests.ps1` | exit 0. `57 passed / 0 failed (total 57)` |
| `git diff --check` | exit 0. Предупреждение Git: LF будет заменён на CRLF при следующем касании `CHANGELOG.md` и `scripts/verify/collect-verifier-pack.ps1` |
| `git diff --cached --check` до абзаца verifier | exit 0. То же предупреждение, и для этого снимка |
| `git diff --cached --stat` до абзаца verifier | 4 files changed, 99 insertions(+), 3 deletions(-). Слов автозакрытия Issue в staged diff нет |

### Диагностика

Подтверждено прогоном, не выводом из чтения кода.

Чтение stderr `gh` текущим кодом сборщика (async stderr, синхронный stdout, затем `WaitForExit`) на объёме `c10-shim-bigerr` + 1048576 символов `x` завершилось. Длина stderr 1048591. Короткий режим `fail` тоже завершился.

Оба `ReadToEndAsync`, затем `WaitForExit`, затем `GetResult`, на том же объёме тоже завершились. Пойманный `Write-Error` этой строки занял 32 мс: текст ошибки наружу не выводился.

Неизменённый `collect-verifier-pack.ps1` против того же shim: метки shim `begin` и `end` различаются на 32 мс (`end` пишется после возврата из записи stderr). Процесс сборщика через 90 с всё ещё был жив, `gh.exe` к этому моменту уже завершился.

`Write-Error` строки `c10-shim-bigerr` плюс N символов `x`, родитель читает оба потока через `ReadToEndAsync` и `WaitForExit`:

| N | Результат |
|---|---|
| 4096 | exit 1 за 566 мс, маркер есть |
| 65536 | exit 1 за 3015 мс, маркер есть |
| 1048576 | за 90010 мс процесс не завершился |

`[Console]::Error.Write` тех же 1048576 символов: exit 4 за 274 мс, длина stderr 1048591, маркер есть, оба чтения завершились.

После правки тот же сборщик: exit 1 за 906 мс, оба чтения завершились, длина stderr 1048627, маркер есть. От метки shim `end` до выхода сборщика 93 мс.

Не подтверждено и в причину правки не входило: что незавершение `Write-Error` на 1 МиБ вызвано контекстом синхронизации. Замер показывает время `Write-Error` и нормальное завершение чтения `gh`. Внутренний алгоритм форматирования ошибки PowerShell не разбирался.

Прогон пакета до правки, дерево чистое, `origin/main` ещё `89953d3`: `name_status_count` 0, `has_unstaged_changes` no, `sessions_count` 0, `sessions_paths` `(none)`. После правки, до этого снимка, `origin/main` уже `76ac75f`: `name_status_count` 1, `has_unstaged_changes` yes, в name-status строка `D protocol/perplexity/project.md`, `sessions_count` 0. Имена полей и их порядок те же. Строка `D` — файл из PR #25, которого нет в базе ветки. В diff скрипта этой строки нет.

### verifier (субагент)

Запущено. Сбор `collect-verifier-pack.ps1 -Issue 19` после staging, до этого абзаца: exit 0. Fingerprint пакета: `branch` `fix/c10-gh-big-stderr-timeout`, `origin_main_sha` `76ac75f2886ed192f413f080221aa542adffe766`, `name_status_count` 5, `has_unstaged_changes` no, `diff_mode` full, `sessions_count` 1, `sessions_paths` `sessions/2026-11-10-c10-gh-big-stderr-timeout.md`.

Субагент вернул отчёт. Input fingerprint совпал с пятью полями шаблона. Подтвердил правку сборщика, снятие пункта README, строку C10 в CHANGELOG и этот снимок. Прогон тестов и PR не засчитывал: в пакете были только записанные результаты, push ещё не был сделан. Единственная лишняя строка name-status — `D protocol/perplexity/project.md`; в status-porcelain её нет. Этот абзац дописан после прогона. Сверка родителем вместо субагента не оформлялась.

## Блокеры

Нет блокера публикации этой правки. `git merge` с новым `origin/main` hook не дал выполнить. Удаления `protocol/perplexity/project.md` в commit нет.

## Следующий шаг

Ревью Perplexity по handoff и merge проверенного SHA, если блокирующих замечаний нет. После merge workflow `release` не запускается: `protocol/version.json` не менялся. Ветка отстаёт от `origin/main` на PR #25; при merge файл `protocol/perplexity/project.md` с main нужно сохранить.

## Перенос на a6f2c0e

PR #27 не смёржен: конфликт с `main` `a6f2c0e4ccf1b0a3dee55b27dd368b0b7fab093f` в `CHANGELOG` `[Unreleased]`. Check runs на этом PR не было. По существу правки замечаний не было.

Вариант (A) не применялся: `origin/fix/c10-gh-big-stderr-timeout` остался на `edf2f3093355e051e73b1b888093fd829e87160f`, разрешения конфликта в UI не было. `git merge` hook по-прежнему не выполняет. `git cherry-pick edf2f3093355e051e73b1b888093fd829e87160f` hook не отклонил.

Ветка `fix/c10-gh-big-stderr-timeout-v2` от `origin/main` `a6f2c0e4ccf1b0a3dee55b27dd368b0b7fab093f`. В `[Unreleased]` первые две строки — C10 и C12, обе есть, C10 первая.

Повтор на этой базе, Windows PowerShell 5.1.20348.4294:

| Проверка | Результат |
|---|---|
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify/tests/test-verifier-pack.ps1` | exit 0. `RESULT: 16 passed / 0 failed (total 16)`. `github-origin-gh-big-stderr` — PASS |
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/hooks/tests/run-guard-tests.ps1` | exit 0. `57 passed / 0 failed (total 57)` |

`exit 1` в функции, отдельный прогон, не по документации. Скрипт: функция вызывает `exit 1`, затем строка `AFTER_FUNCTION`.

- `powershell -File` этого скрипта: процесс завершается с кодом 1, `AFTER_FUNCTION` не печатается. Так тесты запускают сборщик.
- Другой `-File` делает dot-source этого скрипта и затем пишет `AFTER_DOT` и `exit 7`: печатается `AFTER_DOT`, код процесса 7. Хост на `exit 1` не завершился, код 1 наружу не прошёл.
- Dot-source скрипта с `exit 1` на верхнем уровне, не в функции: тот же итог, вызывающий доходит до `exit 7`.

Фраза «exit 1 в функции завершает хост при dot-source» этим замером не подтверждена.

Следующий шаг переноса: ревью нового PR. PR #27 закрывает Perplexity без merge, по поручению владельца.

### verifier (субагент), перенос

Запущено по пакету после staging этого дополнения, до этого абзаца. Fingerprint: `branch` `fix/c10-gh-big-stderr-timeout-v2`, `origin_main_sha` `a6f2c0e4ccf1b0a3dee55b27dd368b0b7fab093f`, `name_status_count` 4, `has_unstaged_changes` no, `diff_mode` full, `sessions_count` 1, `sessions_paths` `sessions/2026-11-10-c10-gh-big-stderr-timeout.md`. Чужих путей нет. Прогоны тестов и новый PR субагент не засчитывал. Этот абзац дописан после прогона.

---
Perplexity 10.11.2026, сессия планирования
- Открытые: #16 C09, #19 C10, #20 C11, #21 C12, #23 W02, #24 C13.
- Порядок (владелец): трек P C12 → W02 → C13; трек E C10 → C11 → C09. Ветки трека P и трека E идут параллельно, CHANGELOG — rebase перед merge.
- Метки: #16 priority:low/stage:intake; #19, #20 priority:medium/stage:intake; #21 priority:medium/stage:in-progress.
- PR #1 (bootstrap) закрыт без merge по решению владельца, ветка сохранена.
- C12: ветка docs/c12-perplexity-project-labels @ 527adf8, PR не создан.
- Кандидаты для conventions-auditor: дубль абзаца «Если субагент недоступен…» в protocol/cycle.md (подтверждено); .gitattributes LF/CRLF; accessibility (решение не принято).
---
