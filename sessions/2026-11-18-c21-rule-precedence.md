---
date: 2026-11-18
task: c21-rule-precedence
refs: "#40"
author: Cursor
---

# C21: приоритет правил потребителя и протокола, ПД в снимке, состав копии

## Задача / ветка / commit

- Issue #40, `Refs #40`. Тип `code`. Карточка выведена. Остановка на «да»: бриф `task-card: СТОП`. Исключение docs-only не применяется: тип `code`; в скоупе `.cursor/skills/task-start/SKILL.md` и `protocol/roles.md`.
- Ответ владельца 18.11.2026: да, с правками. В ссылках конституции — Правило 10 (явное исключение вместо тихого дрейфа) и Правило 11. Персональные данные остаются в Guardrails. Поле манифеста не пишется. Upstream после push — `origin/feat/c21-rule-precedence`.
- Ветка `feat/c21-rule-precedence` от `origin/main` `5061c092f1550d64204bf7871f54b459d7d2f8d7`. Перед созданием ветки дерево было чистым. `git fetch origin`. Blob-ы `origin/main` совпали с брифом: `protocol/cycle.md` `6b43cdcf70fc83b93a43c8df64f82972f1d0475b`, `protocol/roles.md` `ac98c546c743269e15cf8d99ca9922d5ea6a8210`, `.cursor/skills/task-start/SKILL.md` `9f3d1f27e404e6a6e2dd6e598c55057883d89812`, `README.md` `24275230801276b8ac1960ca6255931041bb62f0`, `CHANGELOG.md` `1d5e988a028006b5a919f2898c0f5aa43cd51de3`.
- `AGENTS.md` в репозитории нет. Прочитаны `README.md`, `protocol/roles.md`, `protocol/cycle.md`, `protocol/handoff.md`, `protocol/verdict.md`, Issue #40, комментарий `issuecomment-6976649401`, последний снимок `sessions/2026-11-11-c20-cycle-dedup.md` (образец формата).
- `git switch -c feat/c21-rule-precedence origin/main` поставил upstream на `origin/main`. Публикация — `git push -u origin HEAD`. Upstream после push — `origin/feat/c21-rule-precedence`.
- Этот текст входит в commit ветки. Полный SHA — в handoff.

## Сделано

`protocol/precedence.md`. Три класса. Guardrails: конституция и `protocol/`; без force-push и прямого push в `main`; merge только проверенного SHA; Cursor не выполняет merge; запрет секретов и персональных данных (Правило 11, уровень 1); потребитель только ужесточает; персональные данные — только явное исключение в AGENTS.md потребителя (политика данных и ссылка на решение владельца, Правило 10); других ослаблений Guardrails через AGENTS.md нет. Процесс: `protocol/` — единственный источник; AGENTS.md ссылается и перечисляет ужесточения; ослабление — только изменением `protocol/` через Issue в agentic-protocol. Предмет: политика данных, платформа, стек, что коммитится, стенды; политика данных сама по себе персональные данные не разрешает. Конфликт классов: СТОП, запись в Issue или PR, решение владельца, явное исключение со ссылкой на Правило 11 и Правило 10. Имён потребителей нет.

`protocol/cycle.md`, «Снимок сессии». Предложение «Снимок не содержит секретов и персональных данных.» заменено на: «Снимок не содержит секретов. Персональные данные — только если AGENTS.md потребителя содержит явное исключение с политикой данных и ссылкой на решение владельца (`protocol/precedence.md`); иначе запрещены.» Остальные предложения абзаца те же.

`.cursor/skills/task-start/SKILL.md`, шаг 1: в список `protocol/` добавлен `precedence`. Строка шага 2 `a consumer AGENTS.md may only tighten` не менялась.

`protocol/roles.md`, последний абзац. Скобка `(до манифеста C14 — SHA из Issue/брифа)` заменена на `(SHA из Issue/брифа)`. Дальше то же: только согласованный репозиторий, `scripts/labels/apply-labels.ps1`, создать отсутствующие и обновить цвет/описание, удаление не входит, других прав нет.

`README.md`. В «Составе» строка `protocol/` называет `precedence.md`. Следом за исключением `.github/workflows/` — `protocol/perplexity/**` в копируемый состав не входит. После «Как подключить» добавлены «Допустимые отличия копии» (слаг `o/r` в `scripts/hooks/tests/guard-git.cases.json`, `<owner>/<repo>` в промпте `review-handoff`, `protocol/perplexity/**` не копируется) и «Потребитель с собственными правилами» — одна строка со ссылкой на `protocol/precedence.md`.

`CHANGELOG.md`, под `## [Unreleased]`, строка над C20: `C21 — новый precedence.md, правило ПД в снимке, ссылка меток без C14, состав и отличия копии в README, Issue #40.`

## Решения

В текст вошло Правило 10: явное исключение вместо тихого дрейфа. Правило аудита целостности к задаче не относится. Строка шага 2 `task-start` оставлена: класс «Процесс» уже требует, чтобы AGENTS.md потребителя только ужесточал docs-only. Поле манифеста не названо: схемы нет, Issue #44. `core.autocrlf` не менялся. Файлы UTF-8 без BOM. В индексе все семь путей `i/lf`. Рабочая копия `protocol/roles.md` — CRLF, как до правки. Образец C20 задаёт формат снимка. Его правка `cycle.md` и снятие upstream в этот скоуп не входят.

## Проверки

Среда: Windows PowerShell 5.1.

| Проверка | Результат |
|---|---|
| `rg -n -i "персональн" protocol/` | `protocol/cycle.md:47` и `protocol/precedence.md:9`, `protocol/precedence.md:17` — новая формулировка. Ещё три строки в `protocol/perplexity/project.md` (35, 76) и `protocol/perplexity/README.md` (3): «персональная инструкция», на `origin/main`, каталог в «Не трогать» |
| `rg -n "C14" protocol/ README.md` | совпадений нет, exit 1 |
| `scripts/hooks/tests/run-guard-tests.ps1` | exit 0, `57 passed / 0 failed (total 57)` |
| `scripts/verify/tests/test-verifier-pack.ps1` | exit 0, `16 passed / 0 failed (total 16)` |
| `scripts/labels/tests/test-apply-labels.ps1` | exit 0, `12 passed / 0 failed (total 12)` |
| `git diff --cached --check` | exit 0, без conflict markers. Предупреждение autocrlf на stderr при `git add` и `git diff`. `git ls-files --eol`: у всех семи путей индекс `i/lf` |
| `git diff --cached --stat` | до абзаца verifier: 7 files changed, 96 insertions(+), 5 deletions(-). Семь путей: `.cursor/skills/task-start/SKILL.md`, `CHANGELOG.md`, `README.md`, `protocol/cycle.md`, `protocol/precedence.md`, `protocol/roles.md`, `sessions/2026-11-18-c21-rule-precedence.md` |

Поиск по индексу слов автозакрытия Issue и по секретам — в этом же прогоне, до абзаца verifier: совпадений нет.

### verifier (субагент)

Запущено. Сбор `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify/collect-verifier-pack.ps1 -Issue 40` после staging, до этого абзаца: exit 0. Fingerprint пакета: `branch` `feat/c21-rule-precedence`, `origin_main_sha` `5061c092f1550d64204bf7871f54b459d7d2f8d7`, `name_status_count` 7, `has_unstaged_changes` no, `diff_mode` full, `sessions_count` 1, `sessions_paths` `sessions/2026-11-18-c21-rule-precedence.md`. `git diff --cached --stat` до этого абзаца: 7 files changed, 96 insertions(+), 5 deletions(-).

Субагент вернул отчёт. Input fingerprint совпал со всеми семью полями. Подтвердил семь критериев карточки: новый `protocol/precedence.md` с тремя классами и Правилами 11 и 10, замену предложения в `protocol/cycle.md`, `precedence` в шаге 1 `task-start` при неизменной строке шага 2, скобку SHA в `protocol/roles.md` без расширения права на метки, состав и два раздела README, строку C21 над C20, этот снимок с frontmatter `date`/`task`/`refs`/`author: Cursor`. Claimed but missing: нет. Out of scope: нет. Git субагент не запускал. Три тестовых скрипта и `git diff --cached --check` субагент заново не запускал и своим прогоном не считал. В снимке внутри пакета этого абзаца не было. Абзац дописан после прогона. Сверка родителем вместо субагента не оформлялась.

## Блокеры

Нет блокера публикации. Хвост проверки `персональн`: три прежние строки в `protocol/perplexity/**`.

## Следующий шаг

Ревью Perplexity по handoff и merge проверенного SHA, если блокирующих замечаний нет. Этот pull request не выпускает релиз: `protocol/version.json` не менялся.
