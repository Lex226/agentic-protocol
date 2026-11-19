---
date: 2026-11-19
task: c38-parallel-waves
refs: "#65"
author: Cursor
---

# C38: волны параллельной работы

## Задача / ветка / commit

- Issue #65, `Refs #65`. Тип `code`. Карточка со СТОПом; ответ владельца 19.11.2026: да, с правками 1–4.
- Ветка `c38-parallel-waves` от `origin/main` `ba562bc1c20dd0418c87742d23857a29c52a2a52` (merge PR #73, C39). Перед созданием ветки дерево основного checkout было чистым (ветка `c39-precedence-constitution`). `git fetch origin`. `git ls-remote --heads origin c38-parallel-waves` был пуст. Blob совпали: `protocol/perplexity/project.md` `941b2f89b5d336605bc381a9e414c91bb9713222`, `protocol/cycle.md` `aaa09e426d776a9acd6be6174bf99fb6b763cefa`, `.cursor/skills/task-start/SKILL.md` `aedde3e1611389189bc891b9f8a335e6b6c3f685`, `README.md` `c42abc3279c1a1c2af9235a53d31df3d2586b23a`, `CHANGELOG.md` `b2d307527a456a69a6b9b92607e8a5f2a3a8766a`. `git switch -c` поставил upstream на `origin/main`; затем `git branch --unset-upstream`.
- Работа в основном checkout. Параллельных задач этой волны нет (S2).
- `AGENTS.md` в репозитории нет.
- Этот текст входит в commit ветки. Полный SHA — в handoff.

## Сделано

`protocol/perplexity/project.md`. Тип A, шаг 2: пересечение файлов с другими открытыми PR — неблокирующая находка с порядком merge. Тип D: заголовок «[Cxx]/[Wxx]/[Cxx<буква>]»; объёмный Issue (≥2 независимых блока по разным файлам или >5 файлов скоупа; мягкий признак — code и docs-only вместе) до create_issue предлагается к разбиению, без «да» остаётся одним Issue. Блоки получают суффикс «[Cxx<буква>]» без нового номера Cxx; ветка, клон `../<repo>-<cxx><буква>` и `changelog.d/<cxx><буква>.md` — с тем же суффиксом. Перед стартовым промптом — пункт «Волны»: инвентаризация открытых Issues, таблица, волна без общих файлов (включая `CHANGELOG.md` и `changelog.d/` одного имени), одна задача в основном checkout, порядок merge — очередь, пересечение по телам — [вероятно] до rg в task-card, состав решает владелец, для клона стартовый промпт включает создание клона. Раздел «Персонально» и «персональная инструкция» не менялись.

`protocol/cycle.md`, «Рабочий каталог»: клон создаёт Cursor по стартовому промпту; параллельные задачи не меняют одни и те же файлы; конфликт с main — СТОП, решение владельца. Абзац об удалении клона не менялся. «Версия и релиз»: PR поведения движка добавляет `changelog.d/<cxx>.md` (одна строка в формате записи `[Unreleased]`) и не меняет `CHANGELOG.md`. Релизный PR переименовывает `## [Unreleased]` в `## [<версия>]`, добавляет туда строки из `changelog.d/`, удаляет фрагменты и меняет `protocol/version.json`. Существующие записи `[Unreleased]` остаются до этого релиза.

`README.md`, «Как выпускается релиз»: то же правило фрагментов и то же предложение о релизном PR. Предложения про тег workflow `release`, pre-release и запрет ручного тега сохранены.

`.cursor/skills/task-start/SKILL.md`, шаг 0: поле «Рабочий каталог» необязательное; нет поля или `основной` — этот checkout, отсутствие поля не СТОП. Значение `клон ../<repo>-<cxx>` — в той же сессии `git clone <origin-url> ../<repo>-<cxx>`, окно `cursor` на этом пути, продолжение шага 0 в клоне. Каталог уже есть или окно не открылось — СТОП. Основной checkout не меняется. В «Brief format» то же поле. Строка «Never hardcode…» на месте. Номера Issue, SHA и blob в скилл не добавлены.

`changelog.d/c38.md` — одна строка про волны, блоки `[Cxx<буква>]`, клон и фрагменты (`Refs #65`). `CHANGELOG.md` не менялся. `.github/workflows/` не менялись.

## Решения

Ответ владельца на карточку 19.11.2026: да, с правками.

- 1. В шаге 0 форма клона — `клон ../<repo>-<cxx>`.
- 2. Поле «Рабочий каталог» необязательное. Без поля — основной checkout. Отсутствие поля не СТОП.
- 3. Релизный PR переименовывает `## [Unreleased]` в `## [<версия>]`, добавляет туда строки из `changelog.d/`, удаляет фрагменты и меняет `protocol/version.json`.
- 4. S5: C23b → C23c в клоне; C27 в основном checkout; C40 стартует после merge C23c, в клоне, ∥ C27 (#74).

Контекст S1:

- C36 #63: PR #72, merge `231a7ca`, принят, закрыт (issuecomment-7008354711).
- C39 #66: PR #73, merge `ba562bc`, принят, закрыт (issuecomment-7009394290).
- Сессии: S2 C38 | S3 C25 ∥ C17 | S4 C26 ∥ C23a | S5 — как в пункте 4 | S6 C29 | S7 C16 ∥ C30.
- `stage:intake` снимается при старте задачи по task-card; с #65 снят 19.11.2026.
- Аудит хвостов — #74 C40. `[Unreleased]` — вариант (а): существующие записи C39, C36, C35, C32 остаются до релиза #48 C29. Живая проверка клона — в S3 на C17.

## Проверки

Среда: Windows PowerShell 5.1. Основной checkout.

| Проверка | Результат |
|---|---|
| `Measure-Object -Character` по `protocol/perplexity/project.md` | до правки 5909; после 6880; предел 8000 |
| `rg -n "Unreleased"` без `sessions/` | `CHANGELOG.md:3` заголовок `## [Unreleased]` (вариант (а), файл не менялся); `README.md:39` и `protocol/cycle.md:53`, `protocol/cycle.md:55` — правило фрагментов и сбор на релизе |
| `rg -n "do not clone\|не клонир"` по `.cursor/`, `protocol/`, `README.md` | пусто |
| `rg -n "create_branch\|push_files\|create_or_update_file\|delete_file\|create_pull_request"` в `protocol/perplexity/project.md` | только строка запрета, список разрешённых записей эти имена не содержит |
| `release.yml`, `protocol-check.yml` | оба ищут `## [<VER>]`; в `.github/` нет `Unreleased` и `changelog.d`; файлы не в diff |
| Живая проверка клона и guard | не запущено, правило действует после merge; выполняется в S3 на C17, результат — комментарий в #65 до приёмки |
| `git diff --cached --check` | exit 0, вывод пустой |
| `git diff --cached --stat` | 6 files changed, 93 insertions(+), 10 deletions(-) |

Поиск по индексу: `Closes` только в уже бывшей фразе «не Closes»; `Fixes` и `Resolves` нет; секретов нет.

### verifier (субагент)

Запущено. Сбор `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify/collect-verifier-pack.ps1 -Issue 65` после staging, до этого абзаца: exit 0. Fingerprint пакета: `branch` `c38-parallel-waves`, `origin_main_sha` `ba562bc1c20dd0418c87742d23857a29c52a2a52`, `name_status_count` 6, `has_unstaged_changes` no, `diff_mode` full, `sessions_count` 1, `sessions_paths` `sessions/2026-11-19-c38-parallel-waves.md`. `git diff --cached --stat` до этого абзаца: 6 files changed, 93 insertions(+), 10 deletions(-).

Субагент вернул отчёт. Input fingerprint совпал со всеми семью полями. Подтвердил шесть путей: волны и разбиение в типе D, неблокирующее пересечение в типе A, рабочий каталог и фрагменты в `cycle.md`, то же правило релиза в README, шаг 0 и поле брифа в `task-start`, одна строка `changelog.d/c38.md`, снимок с frontmatter. `CHANGELOG.md` и `.github/workflows/` в индексе нет. Абзац об удалении клона не менялся. Claimed but missing: нет. Out of scope: нет. Git субагент не запускал. дописано после прогона.

## Блокеры

Нет блокера публикации.

#74 п.6 закрывается правилом типа A, шаг 2 (пересечение файлов открытых PR — неблокирующая находка с порядком merge). `protocol/perplexity/project.md` «конституция» и «персональная инструкция» — #74 п.1–2, не правились. Образец C39 менял `protocol/precedence.md` и `CHANGELOG.md` — вне скоупа, не копировалось. Строка C35 «Остаток — #63, #64» не менялась (#74 п.4).

## Следующий шаг

Ревью Perplexity по handoff и merge проверенного SHA, если блокирующих замечаний нет. Issue #65 этим merge не закрывается. После merge владелец вставляет текст `project.md` в Space. Дальше S3: #44 C25 в основном checkout и #31 C17 в клоне. Живая проверка клона — в той сессии на C17, комментарий в #65 до приёмки.
