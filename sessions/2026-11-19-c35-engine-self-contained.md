---
date: 2026-11-19
task: c35-engine-self-contained
refs: "#62"
author: Cursor
---

# C35: движок без ссылок на внешние репо

## Задача / ветка / commit

- Issue #62, `Refs #62`. Тип `code` (hook). Карточка со СТОПом, затем «Ответ владельца: да, с правками». Исключение docs-only не применяется: меняется `scripts/hooks/guard-git.ps1`.
- Ветка `c35-engine-self-contained` от `origin/main` `a49b110c37c0ed864a2ab71980026a833bc8a724` (merge PR #61, C34). Перед созданием ветки дерево было чистым, локальный `main` отставал от origin. `git branch --list c33-guard-invoke-expression` пуст, ветка не удалялась. `git ls-remote --heads origin c35-engine-self-contained` был пуст. Blob-ы брифа совпали с `origin/main`.
- `AGENTS.md` в репозитории нет.
- Параллельно в клоне `../agentic-protocol-c37` идёт #64 C37. Этот checkout его не трогал. `protocol/perplexity/**` не менялся.
- Этот текст входит в commit ветки. Полный SHA — в handoff.

## Сделано

`scripts/hooks/guard-git.ps1`. Только строки причин и комментарии. Каждое `ADR-0003` в причинах заменено на `protocol/roles.md`. `(AGENTS.md / ADR-0003)` стало `(protocol/roles.md)`. Комментарии про неподключённый GitHub MCP без ADR-0005. Логика allow/ask/deny, регулярки и порядок проверок те же. Правка шла через `scripts/hooks/guard-git.next.ps1` (UTF-8 с BOM, как исходник). После двух прогонов тестов байты перенесены в `guard-git.ps1`. `.next.ps1` в commit не входит.

`scripts/hooks/tests/guard-git.cases.json` не менялся: матрица сравнивает код выхода и `permission`, не текст причины. Кейсов 57, как на main.

`protocol/roles.md`, абзац 1: «Правило публикации согласованной задачи.» Последний абзац про метки не менялся.

`README.md`. Удалена строка про конституцию github-playbook. Удалён пункт ограничений про ADR-0003 в причинах guard, без замены.

`PROVENANCE.md`. Слаги в «Источник» и «C13» не менялись. Раздел переименован в «Причины guard»: причины указывают `protocol/roles.md`, комментарии говорят о неподключённом GitHub MCP, логика allow/ask/deny не менялась. Строка таблицы `scripts/hooks/guard-git.ps1` приведена к этому факту.

`CHANGELOG.md`, `## [Unreleased]`: запись C35, Refs #62. Прошлые разделы не менялись.

## Решения

B1. `PROVENANCE.md`: слаги источников — история происхождения. Раздел про имя ADR и строка таблицы guard приведены к факту (19.11.2026, issuecomment-7004517495).

B2. `protocol/perplexity/project.md` не трогать: #64 C37.

B3. `scripts/labels/apply-labels.ps1` и последний абзац `protocol/roles.md` не трогать: #63 C36.

B4. `README.md`: строка про конституцию github-playbook удалена.

Классификация строк вне трёх категорий карточки (ответ владельца 19.11.2026): `adr/ADR-0002-universal-protocol.md` (13 строк) — исключение, Accepted ADR, правится только новой ADR. `protocol/precedence.md:3` — исключение для C35: ссылка задаёт класс «Конституция»; смена — отдельным Issue. Оба файла не менялись.

Критерий повторного `rg`: совпадения только в истории (`sessions/`, `CHANGELOG.md`, `docs/research/`) и исключениях B1–B3 плюс эти два файла.

Абзац 1 `protocol/roles.md` — одна фраза, без «Оно записано в этом файле». Пункт `README.md` про ADR-0003 удалён, не заменён.

Раннер `scripts/hooks/tests/run-guard-tests.ps1` не менялся. Параметр `-Target` есть, значение по умолчанию — `scripts/hooks/guard-git.ps1`.

### Снимок Perplexity

- main: `a49b110c37c0ed864a2ab71980026a833bc8a724` (merge PR #61, C34). #60 закрыт completed. #59 закрыт not planned: guard совпадает с тестами, ask работает, deny для Invoke-Expression не заводить (issuecomment-7003918934).
- Параллель по C32 разрешена. Пишущие субагенты и CLI/headless — нет.
- Созданы #63 C36 (источник меток — параметр) и #64 C37 (`project.md` — шаблон).
- Очередь (решение владельца 19.11.2026): #62 C35 → #63 C36 → #64 C37 → #31 C17 → #44 C25 → #45 C26 → #46 C27 → #42 C23 → #48 C29 → #49 C16 → #50 C30.
- Волны: 1 — C35 (основной) параллельно C37 (клон, без CHANGELOG, merge после C35); 2 — C36 (основной) параллельно C17 (клон, merge C17 после C36).

## Проверки

Среда: Windows PowerShell 5.1. На ask живого хука ответ — отклонить. Запросов ask в этих прогонах не было.

| Проверка | Результат |
|---|---|
| `run-guard-tests.ps1 -Target scripts/hooks/guard-git.next.ps1` | exit 0. `RESULT: 57 passed / 0 failed (total 57)` |
| `run-guard-tests.ps1` по итоговому `guard-git.ps1` | exit 0. `RESULT: 57 passed / 0 failed (total 57) target=...\scripts\hooks\guard-git.ps1` |
| `guard-git.ps1 -CommandString "git merge x"` | exit 2. `{"permission":"deny","user_message":"git merge is blocked for Cursor (protocol/roles.md)","agent_message":"git merge is blocked for Cursor (protocol/roles.md)"}` |
| Живой `git merge x` в Cursor | `Rejected: Command execution was blocked by a hook: {"permission":"deny","user_message":"git merge is blocked for Cursor (protocol/roles.md)","agent_message":"git merge is blocked for Cursor (protocol/roles.md)"}` |
| `git diff` по `guard-git.ps1` | только строки причин и комментарии, перечисленные в «Сделано» |

Повторный `git grep --cached -n -E` с тем же шаблоном: в индексе нет `README.md` и `scripts/hooks/guard-git.ps1`. Совпадения только в истории (`sessions/`, включая этот файл, `CHANGELOG.md:5` и `:28`, `docs/research/2026-11-18-c34-subagent-executors.md`), исключениях B1 (`PROVENANCE.md:5`, `:64`, `:71`), B2 (`protocol/perplexity/project.md`, `protocol/perplexity/README.md`), B3 (`protocol/roles.md:23`, `scripts/labels/apply-labels.ps1`) и двух исключениях владельца (`adr/ADR-0002-universal-protocol.md`, `protocol/precedence.md:3`). `git diff --cached` не содержит `Closes`, `Fixes`, `Resolves` и секретов.

### verifier (субагент)

Запущено. Сбор `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify/collect-verifier-pack.ps1 -Issue 62` после staging, до этого абзаца: exit 0. Fingerprint пакета: `branch` `c35-engine-self-contained`, `origin_main_sha` `a49b110c37c0ed864a2ab71980026a833bc8a724`, `name_status_count` 6, `has_unstaged_changes` no, `diff_mode` full, `sessions_count` 1, `sessions_paths` `sessions/2026-11-19-c35-engine-self-contained.md`. `git diff --cached --stat` до этого абзаца: 6 files changed, 95 insertions(+), 15 deletions(-).

Субагент вернул отчёт. Input fingerprint совпал со всеми семью полями. Подтвердил шесть путей индекса, правку только строк причин и комментариев в `guard-git.ps1`, абзац 1 `protocol/roles.md`, удаления в `README.md`, раздел «Причины guard», слаги «Источник» и «C13» вне hunk, запись C35 в `## [Unreleased]`, frontmatter снимка. `guard-git.cases.json` в индексе нет. Claimed but missing: строка таблицы `PROVENANCE.md` говорила, что комментарии ссылаются на `protocol/roles.md`, а в файле комментарии только снимают ADR и говорят о неподключённом GitHub MCP. Строка приведена к факту раздела: причины ссылаются на `protocol/roles.md`, комментарии говорят о неподключённом GitHub MCP. Эта правка и этот абзац в пакет не входили. Out of scope: нет. Git субагент не запускал. дописано после прогона.

## Блокеры

Нет блокера публикации.

Хвосты этой задачи: `protocol/precedence.md:3` оставляет класс «Конституция» ссылкой на github-playbook; смена — отдельный Issue. Критерий #63 C36 «в protocol/ нет github-playbook» зависит от этой строки. `adr/ADR-0002-universal-protocol.md` остаётся Accepted и в этот скоуп не входит.

Находки для conventions-auditor из #59 issuecomment-7003918934: `rg "персональн"` в `protocol/perplexity/**`; `stage:intake` на закрытых Issues; тела #47, #55, #59 и заголовок #62 устарели; в `protocol/cycle.md` абзацы о verifier и ревью под «Рабочий каталог»; в правилах записи Perplexity нет правки заголовка и тела Issue; метки `research` нет; `docs/` не описан в `README.md`; снимок `perplexity-c32` устарел; кандидат для Space — проверка пересечения файлов параллельных PR в типе A.

## Следующий шаг

Ревью Perplexity по handoff и merge проверенного SHA, если блокирующих замечаний нет. Issue #62 не закрывается этим merge. После merge очередь: #63 C36 в основном checkout и #64 C37 из клона (merge C37 после C35).
