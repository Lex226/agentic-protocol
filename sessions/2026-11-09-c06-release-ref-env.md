---
date: 2026-11-09
task: c06-release-ref-env
refs: "#13"
author: Cursor
---

# C06: проверка ref без переопределения GITHUB_REF

## Задача / ветка / commit

- Issue #13, `Refs #13`. Комментариев в Issue нет. Карточка подтверждена: имя переменной `REF`, меняются строки 35 и 38 `.github/workflows/release.yml`. Два дополнения владельца: строка матрицы `unset REF` и явная пометка, что раннер не проверялся.
- Тип `code`: меняется `.github/`. Исключение docs-only не применялось.
- Ветка `feat/c06-release-ref-env` от `origin/main` `7281333ff952a348b1c140586213a1d81d835ab5`. На момент снимка upstream — `origin/main`.
- Этот текст входит в commit ветки. Полный SHA — в handoff.
- `AGENTS.md` в репозитории нет.

## Сделано

`.github/workflows/release.yml`, шаг «Create release»: в `env` строка 35 — `REF: ${{ github.ref }}`. Условие на строке 38 читает `${REF}` и по-прежнему печатает `release only from main` и завершается с кодом 1, если значение не `refs/heads/main`. Других присвоений `GITHUB_*` / `RUNNER_*` в `env` нет. Чтения `GITHUB_SHA` не менялись.

`CHANGELOG.md`: в `## [Unreleased]` запись «C06 — проверка ref в release.yml без переопределения GITHUB_REF, Issue #13.» Раздел `## [0.2.0-experimental]` на месте (строка 11).

Поведение на раннере GitHub Actions не проверялось: только локальная матрица Git Bash. Workflow `release` по дизайну не запускался.

## Решения

Имя переменной — `REF`. [Variables reference](https://docs.github.com/en/actions/reference/workflows-and-actions/variables), чтение 09.11.2026: значения переменных по умолчанию `GITHUB_*` и `RUNNER_*` переопределить нельзя, такое присвоение игнорируется. `REF` не входит в этот список и не начинается с `GITHUB_`.

Логика релиза не менялась: push → `main`, paths, dry-run, already released, `--prerelease`, разбор `protocol/version.json`, notes из CHANGELOG.

## Проверки

| Проверка | Результат |
|---|---|
| `git diff --check` до снимка | exit 0. Предупреждение Git: LF будет заменён на CRLF при следующем касании `.github/workflows/release.yml` и `CHANGELOG.md` |
| `git diff --cached --name-status` до снимка | `M` `.github/workflows/release.yml`, `M` `CHANGELOG.md` |
| `grep -nE '^\s+(GITHUB\|RUNNER)_[A-Z_]+:' .github/workflows/release.yml` | exit 1, совпадений нет |
| Матрица Git Bash | Условие в `release.yml` на строке 38, `git ls-remote --tags` на строке 52. Фрагмент как в C05, переменная `REF`. `refs/heads/main` → exit 0, `continue dry=false`. `refs/heads/feat/x` → exit 1, `release only from main`. При `REF=refs/heads/main`: push+true → dry false; push+пусто → dry false; workflow_dispatch+true → dry true; workflow_dispatch+false → dry false |
| `unset REF` | exit 1. Фактический вывод: `bash: line 3: REF: unbound variable`. Маркер продолжения после проверки ref не напечатан |
| `grep -F -x "## [0.2.0-experimental]" CHANGELOG.md` | exit 0, строка 11 |
| `git diff origin/main -- protocol/version.json` | пусто, exit 0 |
| actionlint | не запущено: нет бинаря |
| Слова автозакрытия Issue и типовые секреты в staged diff до снимка | совпадений нет |
| `scripts/verify/collect-verifier-pack.ps1 -Issue 13` | exit 0. Пакет без этого снимка: `name_status_count` 2, `has_unstaged_changes` no, `diff_mode` full, `origin_main_sha` `7281333ff952a348b1c140586213a1d81d835ab5` |
| `protocol-check` на HEAD PR | на момент снимка не запущено: push ещё не сделан |
| workflow `release` | не запущено, по дизайну: `protocol/version.json` не менялся, push не в `main`. Поведение на раннере не проверялось |

### verifier (субагент)

Запущено. Сбор пакета — строка таблицы выше.

Прогон по пакету Issue #13 и подтверждённой карточке: субагент вернул отчёт. Input fingerprint совпал с пакетом (`branch` `feat/c06-release-ref-env`, `origin_main_sha` `7281333ff952a348b1c140586213a1d81d835ab5`, `name_status_count` 2, `has_unstaged_changes` no, `diff_mode` full). Подтвердил `REF` на строках 35 и 38, отсутствие других присвоений `GITHUB_*` / `RUNNER_*` и запись C06 в `[Unreleased]`. Матрицу Git Bash, снимок, `protocol-check` и PR по пакету не засчитывал. Снимок в пакете отсутствовал — известный пробел пакета, Issue #14. Сверка родителем вместо субагента не оформлялась.

## Блокеры

Нет блокера публикации.

## Следующий шаг

Ревью Perplexity по handoff и merge проверенного SHA, если блокирующих замечаний нет. После merge workflow `release` не запускается: `protocol/version.json` не менялся.

---
Perplexity 09.11.2026, сессия C05
- PR #12 (C05) смёржен: merge 7281333ff952a348b1c140586213a1d81d835ab5, HEAD 043f11e. protocol-check success (run 42669048499).
- После merge: release на 7281333 не запускался (gh run list пусто, со слов Cursor); Releases = 1 (v0.2.0-experimental → 6dbae64); новых тегов нет.
- Issue #11 закрыт (completed) после приёмки владельцем.
- Созданы Issue: #13 [C06] GITHUB_REF в release.yml; #14 [C07] снимок в пакете verifier; #15 [C08] CHANGELOG PR #10 (docs-only); #16 [C09] перенос строки task-start.
- Решение владельца по #14: вариант 1 — секция sessions/ по diff ветки относительно origin/main (комментарий в #14).
- Метки priority:low/medium и stage:intake: решено создать; создаёт владелец через gh, Perplexity не создавала.
- У владельца: tag rules v* в public agentic-protocol (по умолчанию не настраивать).
---
