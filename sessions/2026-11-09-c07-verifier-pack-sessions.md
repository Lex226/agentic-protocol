---
date: 2026-11-09
task: c07-verifier-pack-sessions
refs: "#14"
author: Cursor
---

# C07: снимок сессии в пакете verifier

## Задача / ветка / commit

- Issue #14, `Refs #14`. Комментарий «Решение владельца (09.11.2026)»: вариант 1. Вариант 2 не делается.
- Тип `code`. Карточка подтверждена Perplexity, блокирующих правок нет. Четыре неблокирующих замечания учтены при реализации.
- Ветка `feat/c07-verifier-pack-sessions` от `origin/main` `239758916c7d7e59540b9111448b5fc7d71e28b3`.
- Этот текст входит в commit ветки. Полный SHA — в handoff.
- `AGENTS.md` в репозитории нет.

## Сделано

`scripts/verify/collect-verifier-pack.ps1`: отдельная секция `## sessions`. Список путей — объединение без дублей, сортировка `[StringComparer]::Ordinal`:

- `git diff --name-status origin/main...HEAD -- sessions/`
- `git diff --cached --name-status -- sessions/`
- `git diff --name-status -- sessions/`
- `git ls-files --others --exclude-standard -- sessions/`

Содержимое читается из рабочего дерева: `Get-Content -LiteralPath -Raw -Encoding UTF8`. Если пути в списке нет на диске, в блоке строка `файл удалён в рабочем дереве`. Пустой список: строка `снимок сессии не найден`, сбор завершается с exit 0.

В fingerprint добавлены только `sessions_count` и `sessions_paths` (при пустом списке `(none)`). Команды cached diff не фильтруют `sessions/`: `git diff --cached --name-status origin/main` и `git diff --cached origin/main` остаются прежними. `MaxDiffBytes` по-прежнему обрезает только `## diff`. Если текст секции `sessions` больше `MaxDiffBytes`, в пакет пишется строка-предупреждение, текст секции не обрезается.

`scripts/verify/tests/test-verifier-pack.ps1`: случаи `sessions-absent`, `sessions-untracked`, `sessions-staged`. Маркер содержимого — `МаркерСнимкаКириллица`.

`CHANGELOG.md`, раздел `## [Unreleased]`: `C07 — снимок сессии из sessions/ в пакете verifier, Issue #14.`

## Решения

`sessions/` остаётся в основном `name-status` и `## diff`. Отдельная секция добавляется сверху, строки cached diff не получают фильтр. Так `name_status_count` сохраняет прежний смысл, а неотслеживаемый снимок, которого в cached diff нет, всё равно попадает в пакет.

`.cursor/agents/verifier.md` не менялся. Строки 25–28 требуют в пакете как минимум `branch`, `origin_main_sha`, `name_status_count`, `has_unstaged_changes`, `diff_mode`. Формат отчёта на строках 51–60 повторяет только эти пять полей. `sessions_count` и `sessions_paths` в этот список не входят. Субагент, который примет список отчёта за закрытый набор полей пакета, может отметить ложное несовпадение. Это не правка движка: файл вне скоупа.

Предупреждение о размере секции `sessions` сделано в сборщике, а не оставлено хвостом.

`collect-verifier-pack.ps1` записан в UTF-8 с BOM. Без BOM Windows PowerShell 5.1 читает скрипт в системной кодировке и не разбирает кириллические литералы `снимок сессии не найден` и `файл удалён в рабочем дереве`. У `test-verifier-pack.ps1` BOM уже был.

## Проверки

| Проверка | Результат |
|---|---|
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify/tests/test-verifier-pack.ps1` | exit 1. `RESULT: 15 passed / 1 failed (total 16)`. PASS: прежние случаи, кроме одного, и `sessions-absent`, `sessions-untracked`, `sessions-staged`. FAIL: `github-origin-gh-big-stderr: timeout` |
| Тот же прогон со сборщиком `origin/main` | exit 1. `12 passed / 1 failed (total 13)`. Тот же FAIL `github-origin-gh-big-stderr: timeout`. Новый код этот случай не добавлял |
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/hooks/tests/run-guard-tests.ps1` | exit 0. `57 passed / 0 failed (total 57)` |
| `collect-verifier-pack.ps1 -Issue 14` во временном worktree на `origin/main` `239758916c7d7e59540b9111448b5fc7d71e28b3` | повтор после восстановления PATH: exit 0. `sessions_count: 0`, `sessions_paths: (none)`, в секции строка `снимок сессии не найден`. Worktree удалён. Первый запуск в той же оболочке был exit 1: PATH ещё указывал на тестовый `gh.exe` после отладки (`GH_SHIM_MODE=bigerr`); к результату не относится |
| `git diff --cached --check` | exit 0. Предупреждение Git: LF будет заменён на CRLF при следующем касании `CHANGELOG.md`, `scripts/verify/collect-verifier-pack.ps1`, `scripts/verify/tests/test-verifier-pack.ps1` и этого снимка |
| `git diff --cached --stat` до абзаца с итогом verifier | exit 0. Четыре файла: `CHANGELOG.md`, `scripts/verify/collect-verifier-pack.ps1`, `scripts/verify/tests/test-verifier-pack.ps1`, этот снимок. Точный stat этого снимка снят до абзаца verifier и повторяется в отчёте по команде |
| Слова автозакрытия Issue и типовые секреты в staged diff | совпадений нет |
| `protocol-check` на HEAD PR | на момент снимка не запущено: push ещё не сделан |
| workflow `release` | не запущено, по дизайну: `protocol/version.json` не менялся |

### verifier (субагент)

Запущено. Сбор `collect-verifier-pack.ps1 -Issue 14`: exit 0. Fingerprint пакета: `branch` `feat/c07-verifier-pack-sessions`, `origin_main_sha` `239758916c7d7e59540b9111448b5fc7d71e28b3`, `name_status_count` 4, `has_unstaged_changes` no, `diff_mode` full, `sessions_count` 1, `sessions_paths` `sessions/2026-11-09-c07-verifier-pack-sessions.md`.

Субагент вернул отчёт. Input fingerprint совпал с пятью полями шаблона отчёта. Поля `sessions_count` и `sessions_paths` в шаблон не входят; субагент не назвал их отсутствие в отчёте неполнотой пакета и подтвердил оба в разделе Confirmed. Секция `## sessions` содержит текст этого снимка. Прогон тестов и PR субагент не засчитывал: на момент пакета в снимке был exit 1 из-за `github-origin-gh-big-stderr`, push ещё не был сделан. Этот абзац дописан после прогона. Сверка родителем вместо субагента не оформлялась.

## Блокеры

Нет блокера публикации. Timeout `github-origin-gh-big-stderr` воспроизводится на сборщике `origin/main` и в эту задачу не входит.

## Следующий шаг

Ревью Perplexity по handoff и merge проверенного SHA, если блокирующих замечаний нет. После merge workflow `release` не запускается: `protocol/version.json` не менялся.

---
Perplexity 09.11.2026, сессия C06
- PR #17 (C06) смёржен: merge 239758916c7d7e59540b9111448b5fc7d71e28b3, HEAD d68f1b5. protocol-check success (run 42676747264).
- После merge Releases = 1 (v0.2.0-experimental). Запуски Actions на 2397589 Perplexity не читала (в коннекторе нет Actions).
- Issue #11 и #13 закрыты (completed) после приёмки владельцем.
- #14: решение владельца — вариант 1 (секция sessions/ по diff ветки, комментарий в Issue).
- Открыты: #14 (C07), #15 (C08 docs-only), #16 (C09 .cursor/).
- Кандидат для conventions-auditor: .gitattributes для LF/CRLF (*.yml, *.md); Issue не заведён.
- Метки priority:*/stage:intake: создаёт владелец через gh; факт создания Perplexity не проверяла.
---
