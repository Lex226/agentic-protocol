---
date: 2026-11-09
task: c04-release-automation
refs: "#9"
author: Cursor
---

# C04: версия 0.2.0-experimental и автоматический релиз

## Задача / ветка / commit

- Issue #9, `Refs #9`. Комментарий «Решения владельца (09.11.2026)» важнее тела Issue. Карточка подтверждена с правками по dry-run, `fetch-depth`, concurrency, шаблону версии, строке C01, одной команде awk и правилу «тег без Release = already released».
- Ветка `feat/c04-release-automation` от `origin/main` `bb683516accd4136cc0adc7c763c6ea96e7ba186`.
- Этот текст входит в commit ветки. Полный SHA — в handoff.

## Сделано

`protocol/version.json` содержит только `{"protocol_version": "0.2.0-experimental"}`.

`README.md`: строка версии `0.2.0-experimental`; «Как подключить» — с тега `v0.2.0-experimental`, тег совпадает с `protocol_version`; раздел «Как выпускается релиз» — четыре предложения.

`CHANGELOG.md`: пустой `## [Unreleased]`; `## [0.2.0-experimental]` (C02 #4 / PR #7, C03 #6 / PR #8, C04 #9); `## [0.1.1-experimental]` (MIT, PR #5, тег `v0.1.1-experimental` на `3323a8e` без смены `version.json`); `## [0.1.0-experimental]` — «C01 — импорт движка, Issue #2; см. sessions/2026-11-09-c01-import.md», коммиты не перечислены.

`protocol/cycle.md`: раздел «Версия и релиз».

`.github/workflows/protocol-check.yml`: `pull_request` → `main`, `contents: read`, `actions/checkout` с `fetch-depth: 0`, база через `git show origin/<base>:protocol/version.json`. JSON с одним полем, версия по `^\d+\.\d+\.\d+(-[0-9A-Za-z.]+)?$`, в CHANGELOG есть `## [<версия>]`. Если версия отличается от base и тег `v<версия>` уже есть — fail.

`.github/workflows/release.yml`: `push` → `main` по пути `protocol/version.json` и `workflow_dispatch` (`dry_run`, default `true`); `concurrency` group `release`, `cancel-in-progress: false`; `contents: write` только на job. Тег есть — exit 0 `already released`. Раздел CHANGELOG извлекает одна команда awk; нет раздела — fail. Иначе `gh release create` на `$GITHUB_SHA`, `--prerelease` при `-` в версии. Dry-run только при `workflow_dispatch` и `inputs.dry_run == true`. `GH_TOKEN` — `${{ github.token }}`. Только `actions/checkout`.

## Решения

Задача типа `code`: меняются `protocol/version.json` и `.github/`. Исключение docs-only не применялось. Продолжение — после «да» владельца.

Dry-run не включается на `push`, даже если значение input по умолчанию `true`. Тег без GitHub Release считается уже выпущенным.

Локальные `git tag` и `gh release` не выполнялись. Существующие теги не переносились.

## Проверки

| Проверка | Результат |
|---|---|
| `git diff --cached --check` до снимка | exit 0 |
| `git diff --cached --stat` до снимка | 6 files changed, 166 insertions(+), 3 deletions(-), exit 0. Файлы: `protocol/version.json`, `README.md`, `CHANGELOG.md`, `protocol/cycle.md`, `.github/workflows/protocol-check.yml`, `.github/workflows/release.yml` |
| JSON `protocol/version.json` | `ConvertFrom-Json`: одно поле `protocol_version` = `0.2.0-experimental` |
| Шаблон версии | `py -3`, `re.fullmatch`: `valid=True` |
| Заголовок `## [0.2.0-experimental]` | `grep -F -x`, exit 0 |
| awk раздела CHANGELOG (Git Bash) | exit 0. Тело: пустая строка и три пункта C02, C03, C04 |
| Матрица dry-run в Git Bash | `push` + input `true` → dry false; `push` + пустой input → dry false; `workflow_dispatch` + `true` → dry true; `workflow_dispatch` + `false` → dry false |
| `git ls-remote --tags origin refs/tags/v0.2.0-experimental` | пусто, exit 0 |
| `git ls-remote --tags origin refs/tags/v0.1.1-experimental` | тег есть, exit 0. Для этой версии сработало бы `already released` |
| actionlint | не запущено: нет actionlint |
| `Closes` / `Fixes` / `Resolves` и типовые секреты в staged diff до снимка | совпадений нет |
| `scripts/verify/collect-verifier-pack.ps1 -Issue 9` | exit 0. Пакет без этого снимка: `name_status_count` 6, `has_unstaged_changes` no, `diff_mode` full, `origin_main_sha` `bb683516accd4136cc0adc7c763c6ea96e7ba186` |
| `protocol-check` на HEAD PR | на момент снимка не запущено: push ещё не сделан |
| workflow `release` | не запущено, по дизайну: до merge в `main` не запускается |

### verifier (субагент)

Запущено. Сбор пакета — строка таблицы выше.

Прогон по пакету Issue #9 и подтверждённой карточке: субагент вернул отчёт. Input fingerprint совпал с пакетом (`branch` `feat/c04-release-automation`, `origin_main_sha` `bb683516accd4136cc0adc7c763c6ea96e7ba186`, `name_status_count` 6, `has_unstaged_changes` no, `diff_mode` full). Подтвердил версию, README, CHANGELOG, раздел «Версия и релиз» и оба workflow. Снимок в пакете отсутствовал — это отмечено как пробел пакета. PR на момент прогона не существовал и не засчитывался. Чужих путей в пакете не было. Сверка родителем вместо субагента не оформлялась.

## Блокеры

Нет блокера публикации. Ручная проверка видимости репозитория, минут Actions, Workflow permissions и tag rules `v*` остаётся у владельца.

## Следующий шаг

Ревью Perplexity по handoff и merge проверенного SHA, если блокирующих замечаний нет. После merge Perplexity проверяет прогон `release`: тег `v0.2.0-experimental` равен merge commit, Release — pre-release. Повторный запуск должен закончиться `already released`.

---
Perplexity 09.11: PR #8 смёржен (bb68351), #6 закрыт. #9 создан; решения: 0.2.0-experimental, релиз через Actions, субагент не нужен. Ручная проверка: видимость репо/минуты Actions, Workflow permissions, tag rules v*.
---
