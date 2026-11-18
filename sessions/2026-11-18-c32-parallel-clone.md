---
date: 2026-11-18
task: c32-parallel-clone
refs: "#55"
author: Cursor
---

# C32: отдельный клон на параллельную задачу

## Задача / ветка / commit

- Issue #55, `Refs #55`. Тип `code`. Карточка со СТОПом, затем «да, с правками». Исключение docs-only не применяется: меняется `.cursor/skills/task-start/SKILL.md`.
- Ветка `c32-parallel-clone` от `origin/main` `5bd1983a91da7fed8c5f5f09a69da53595d2576c` (merge PR #57, C28). Перед созданием ветки дерево было чистым. `git ls-remote --heads origin c32-parallel-clone` был пуст. Blob-ы брифа совпали с `origin/main`.
- `AGENTS.md` в репозитории нет.
- Этот текст входит в commit ветки. Полный SHA — в handoff.

## Сделано

`protocol/cycle.md`. Раздел «Рабочий каталог»: задачи последовательно в основном checkout; параллельная задача — отдельный клон `../<repo>-<cxx>`, одно окно Cursor на клон; ветка только в одном клоне (`git ls-remote --heads origin <branch>`, не пусто → СТОП); клон удаляется только после merge, при чистом `git status` и пустом `git log origin/<branch>..HEAD`; на старте дерево чистое. Перед сбором пакета нет неиндексированных правок и неотслеживаемых файлов — все правки задачи в индексе (`has_unstaged_changes: no`). При `yes` родитель не передаёт пакет субагенту, приводит дерево к staged-набору и собирает пакет заново. СТОП относится к пакету, который передаётся субагенту. Правка снимка после прогона verifier индексируется заново перед commit; пакет повторно не собирается; в снимке пометка «дописано после прогона».

`.cursor/skills/task-start/SKILL.md`. Шаг 0: параллельная задача — `git clone` в `../<repo>-<cxx>`, затем те же шаги в клоне; последовательная — те же шаги в основном checkout, без клона. Чистое `git status`, `git fetch origin`, пустой `git ls-remote --heads origin <branch>`, `git switch -c <branch> origin/main`. Прежняя сверка blob и запрет сравнивать SHA из брифа сохранены. Шаг 6: то же правило индекса и СТОП при `has_unstaged_changes: yes`. Номеров Issue, SHA, blob и путей диска в скилле нет.

`CHANGELOG.md`, `## [Unreleased]`: запись C32, Issue #55.

`scripts/verify/collect-verifier-pack.ps1` и `.cursor/agents/verifier.md` не менялись.

## Решения

Вариант изоляции — C по умолчанию + D для параллельной задачи (`issuecomment-6987069086`, 18.11.2026). Отклонены A (`git worktree add`), B (Cursor worktrees), E (облачные агенты), F (Docker/devcontainer).

`has_unstaged_changes: yes` — СТОП у родителя. Сборщик не меняется: поле уже становится `yes` при неиндексированной правке и при любом `??`. `verifier.md` в C32 не меняется. Согласование с hard stop 1 — в #31 (C17), комментарием Perplexity после merge C32 (`#31` `issuecomment-6986155580`).

Критерий перед пакетом: нет неиндексированных правок и неотслеживаемых файлов, все правки задачи в индексе (`has_unstaged_changes: no`).

Cursor Docs «Worktrees», чтение 18.11.2026: https://cursor.com/docs/configuration/worktrees. `cursor.worktreeMaxCount` по умолчанию 25 на машину; с Cursor 3.5 автоочистка затрагивает и каталоги из `git worktree add`. Про отдельные клоны в документации не упомянуто.

Заголовок Issue #55 сменил владелец: «[C32] Параллельная работа агентов: отдельный клон на задачу». Тело #55 по-прежнему описывает worktree и устарело. При расхождении действует `issuecomment-6987069086`. Если verifier отметит расхождение тела — это не отсутствие правки.

## Проверки

Среда: Windows PowerShell 5.1.

| Проверка | Результат |
|---|---|
| `git diff --cached --check` | exit 0, вывод пустой |
| `git diff --cached --stat` | 5 files changed, 108 insertions(+), 5 deletions(-): `SKILL.md`, `CHANGELOG.md`, `protocol/cycle.md`, оба снимка |
| `Closes\|Fixes\|Resolves` и секреты в индексе | `Closes #` / `Fixes #` / `Resolves #` нет. Слова паттерна есть в тексте скилла и в этой строке. Секретов нет |
| guard в клоне | `git clone https://github.com/Lex226/agentic-protocol.git` в `../agentic-protocol-c32-guard`, `git switch --detach origin/main` → HEAD `5bd1983`. `git config --show-origin core.hooksPath`: вывод пустой, exit 1. `run-guard-tests.ps1`: `RESULT: 57 passed / 0 failed (total 57) target=C:\Users\Capaeev\GitHub Repo\agentic-protocol-c32-guard\scripts\hooks\guard-git.ps1`, exit 0. `git status --porcelain` пустой, exit 0. Каталог клона удалён |
| хук `.cursor/hooks.json` в окне Cursor на клоне | требует ручной проверки. Deny-кейсы вживую не запускались: при отказе guard опасны push в main, `--force`, `gh pr merge`. Безопасного кейса нет |
| тест сборщика | не запускался: `collect-verifier-pack.ps1` не менялся |

### verifier (субагент)

Запущено. Сбор `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify/collect-verifier-pack.ps1 -Issue 55` после staging, до этого абзаца: exit 0. Fingerprint пакета: `branch` `c32-parallel-clone`, `origin_main_sha` `5bd1983a91da7fed8c5f5f09a69da53595d2576c`, `name_status_count` 5, `has_unstaged_changes` no, `diff_mode` full, `sessions_count` 2, `sessions_paths` `sessions/2026-11-18-c32-parallel-clone.md, sessions/2026-11-18-perplexity-c32.md`. `git diff --cached --stat` до этого абзаца: 5 files changed, 108 insertions(+), 5 deletions(-).

Субагент вернул отчёт. Input fingerprint совпал со всеми семью полями. Подтвердил критерии карточки: раздел «Рабочий каталог»; шаг 0 и шаг 6 `task-start`; сборщик и `verifier.md` вне diff; запись C32 в `## [Unreleased]`; оба снимка с frontmatter; `worktrees.json` не создан; `has_unstaged_changes: no`. Claimed but missing: нет. Out of scope: тело Issue #55 описывает worktree (не отсутствие правки); живой хук `.cursor/hooks.json` в окне клона не запускался. Git субагент не запускал. дописано после прогона.

## Блокеры

Нет блокера публикации. Хвосты для conventions-auditor: `rg "персональн"` задевает `protocol/perplexity/**` (`README.md:3`, `project.md:35`, `project.md:76`); `stage:intake` остаётся на закрытых Issues; тело #47 устарело относительно комментариев владельца. Тело #55 устарело относительно `issuecomment-6987069086` — в «Решения», не отсутствие правки.

## Следующий шаг

Ревью Perplexity по handoff и merge проверенного SHA, если блокирующих замечаний нет. Issue #55 не закрывается этим merge. После merge Perplexity пишет в #31 комментарий о согласовании hard stop 1 с правилом C32. Очередь: #31 C17.
