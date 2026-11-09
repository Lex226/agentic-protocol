---
date: 2026-11-09
task: c05-free-private-baseline
refs: "#11"
author: Cursor
---

# C05: работа без серверной защиты и релиз только с main

## Задача / ветка / commit

- Issue #11, `Refs #11`. Комментарий «Решение владельца (09.11.2026): дополнение скоупа» дополняет тело. Карточка подтверждена с правками: цитата rulesets подтверждена; protected branches цитируются со страницы About protected branches; required status checks — вывод про настройку branch protection; в `platform.md` — админы и список обхода; в проверке потребителя указаны скрипты его копии движка и SHA/версия.
- Тип `code`: меняется `.github/`. Исключение docs-only не применялось.
- Ветка `feat/c05-free-private-baseline` от `origin/main` `6dbae643daf159658cd67778dc0ff7b6ee83d21d`. Upstream не на `main`.
- Этот текст входит в commit ветки. Полный SHA — в handoff.

## Сделано

`protocol/platform.md`: раздел «Работа без серверной защиты». Базовая линия — private на GitHub Free. Протокол не требует rulesets, protected branches и required status checks. Их место занимают guard в IDE, merge ревьюером по `expectedHeadSha`, сверка check runs («CI нет» не считается зелёным) и запрет force-push и прямого push в `main`. Доступная защита рекомендуется и не обязательна. По умолчанию branch protection не применяется к администраторам; список обхода — только у репозитория организации, поэтому у личного аккаунта-владельца процесс остаётся основной защитой и на платном плане.

`README.md`: в «Состав» и «Как подключить» `.github/workflows/` относятся к `agentic-protocol` и потребителю не копируются. Матрица public/private × Free/платный со ссылками на docs.github.com и датой чтения 09.11.2026. Цитаты rulesets и protected branches — из блоков «Who can use this feature?». Required status checks помечены как вывод: настройка branch protection rule, доступная там же, где protected branches.

`.github/workflows/release.yml`: в шаге «Create release» до проверки тега `GITHUB_REF != refs/heads/main` печатает `release only from main` и завершается с кодом 1. Push → `main`, dry-run, `already released` и `--prerelease` не менялись. `protocol/version.json` не менялся.

`CHANGELOG.md`: четыре записи C05 в `## [Unreleased]`. Раздел `## [0.2.0-experimental]` на месте.

## Решения

Раздел записан в новый `protocol/platform.md`, не в `protocol/cycle.md`.

Отказ релиза не с `main` — явный fail в шаге, не условие job. `workflow_dispatch` с не-`main` завершается ошибкой и при `dry_run=true`.

Фраза About rulesets про customers on GitHub Team and GitHub Enterprise отнесена к rulesets уровня организации, не к доступности ruleset репозитория.

`protocol/verdict.md` не менялся. Строка «требуемые проверки» и «Защита ветки не обходится» не делает включение rulesets, protected branches или required status checks условием шага.

## Проверки

| Проверка | Результат |
|---|---|
| `git diff --cached --check` до снимка | exit 0 |
| `git diff --cached --stat` до снимка | 4 files changed, 59 insertions(+), 2 deletions(-), exit 0. Файлы: `.github/workflows/release.yml`, `CHANGELOG.md`, `README.md`, `protocol/platform.md` |
| Матрица ref и dry-run в Git Bash | Условие в `release.yml` на строке 38, `git ls-remote --tags` на строке 52. `refs/heads/main` → exit 0, продолжение. `refs/heads/feat/x` → exit 1, `release only from main`. При ref `main`: push+true → dry false; push+пусто → dry false; workflow_dispatch+true → dry true; workflow_dispatch+false → dry false |
| Поиск формулировок-условий в `protocol/` и README | Обязательного требования rulesets, protected branches или required status checks как условия шага нет |
| `grep -F -x "## [0.2.0-experimental]" CHANGELOG.md` | exit 0, строка 10 |
| `git diff origin/main -- protocol/version.json` | пусто |
| actionlint | не запущено: нет actionlint |
| `Closes` / `Fixes` / `Resolves` и типовые секреты в staged diff до снимка | совпадений нет |
| `gh auth status` | exit 0. Аккаунт Lex226, scope `repo`. `Lex226/1c-document-collection`: `visibility` PRIVATE |
| `collect-verifier-pack.ps1 -Issue 38` в копии движка потребителя | exit 0. `origin_main_sha` `54a6f2d0203bc0ad3bd5914271ab3793cd722a8c`, `name_status_count` 0. Пакет записан вне дерева и удалён. `git status` потребителя пустой |
| `run-guard-tests.ps1` в копии движка потребителя | exit 0. 57 passed / 0 failed. `git status` потребителя пустой |
| `scripts/verify/collect-verifier-pack.ps1 -Issue 11` | exit 0. Пакет без этого снимка: `name_status_count` 4, `has_unstaged_changes` no, `diff_mode` full, `origin_main_sha` `6dbae643daf159658cd67778dc0ff7b6ee83d21d` |
| `protocol-check` на HEAD PR | на момент снимка не запущено: push ещё не сделан |
| workflow `release` | не запущено, по дизайну: `protocol/version.json` не менялся, push не в `main` |

Скрипты п. 3 взяты из копии движка в `Lex226/1c-document-collection` (`C:\Users\Capaeev\GitHub Repo\1c-document-collection`), не из рабочего дерева этой ветки. SHA копии — HEAD потребителя `54a6f2d0203bc0ad3bd5914271ab3793cd722a8c` (`main`). Отдельного `protocol/version.json` в потребителе нет; ADR-0005 называет копию «Движок v0». Blob `scripts/verify/collect-verifier-pack.ps1`, `scripts/hooks/tests/run-guard-tests.ps1` и `scripts/hooks/guard-git.ps1` совпадает с теми же путями в `agentic-protocol` на `6dbae643daf159658cd67778dc0ff7b6ee83d21d`. В потребителе ничего не коммитилось и не пушилось.

### verifier (субагент)

Запущено. Сбор пакета — строка таблицы выше.

Прогон по пакету Issue #11, комментарию владельца и подтверждённой карточке: субагент вернул отчёт. Input fingerprint совпал с пакетом (`branch` `feat/c05-free-private-baseline`, `origin_main_sha` `6dbae643daf159658cd67778dc0ff7b6ee83d21d`, `name_status_count` 4, `has_unstaged_changes` no, `diff_mode` full). Подтвердил `platform.md`, матрицу README, четыре записи `[Unreleased]` и fail в `release.yml` до проверки тега. Прогон потребителя и матрицу Git Bash по пакету не засчитывал. Снимок в пакете отсутствовал — известный пробел пакета. Чужих путей в пакете не было. Сверка родителем вместо субагента не оформлялась.

## Блокеры

Нет блокера публикации. Ручная проверка tag rules `v*` в public `agentic-protocol` остаётся у владельца; по умолчанию не настраивать.

## Следующий шаг

Ревью Perplexity по handoff и merge проверенного SHA, если блокирующих замечаний нет. После merge workflow `release` не запускается: `protocol/version.json` не менялся.

---
Perplexity 09.11.2026, сессия C03–C04
- PR #8 (C03) смёржен: bb68351, Issue #6 закрыт.
- PR #10 (C04) смёржен: 6dbae64, Issue #9 закрыт. protocol-check success (run 42658339692).
- Release v0.2.0-experimental: тег → 6dbae64, pre-release, автор github-actions[bot]. Releases = 1. Лог повторного прогона Perplexity не читала.
- Решения владельца: версия 0.2.0-experimental; тег/Release/changelog — через Actions, субагент не нужен; план GitHub Free — протокол не опирается на rulesets/protected branches/required checks; release только с main (комментарий #11).
- Открыто: #11 (C05); PR #1 отложен (workflow protocol-ci).
- Хвосты вне C05: ссылка на PR #10 в CHANGELOG; перенос строки шага 2 в task-start; снимок не попадает в пакет verifier.
- Ручная проверка у владельца: tag rules v* в public agentic-protocol (по умолчанию не настраивать).
---
