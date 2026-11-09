---
date: 2026-11-09
task: c03-docs-only-exception
refs: "#6"
author: Cursor
---

# C03: исключение docs-only

## Задача / ветка / commit

- Issue #6, `Refs #6`. Решение владельца 09.11.2026. Ответ на карточку: да, с правками — публикация явным именем ветки; строка 31 скилла как в карточке, перенос и следующая строка сохранены.
- Ветка `docs/c03-docs-only-exception` от `origin/main` `7cd190b7d00da7e460eaf2ce03de50ed297a31eb`.
- Этот текст входит в commit ветки. Полный SHA — в handoff.

## Сделано

В `protocol/cycle.md` добавлен раздел «Исключение docs-only» после абзаца про замечания ревью и перед «Снимок сессии». Если все условия выполнены сразу, карточка выводится и работа продолжается без остановки на «да». Условия: тип в брифе `docs-only`; скоуп по пунктам задан владельцем в Issue или брифе; меняются только `*.md` вне `.cursor/` и снимок сессии; не затрагиваются `scripts/`, `.cursor/`, `protocol/version.json`, LICENSE, теги и настройки GitHub; не меняются `protocol/roles.md`, `verdict.md` и `handoff.md`. Нарушение условия, неясный пункт или новое требование — СТОП. Карточка выводится всегда. Проверки, снимок, PR, handoff и независимое ревью обязательны.

В `.cursor/skills/task-start/SKILL.md` изменена одна строка шага 2: продолжение ссылается на раздел `protocol/cycle.md` «Исключение docs-only»; `AGENTS.md` потребителя может только ужесточать это правило. Строка `otherwise treat as СТОП and say so` на месте.

## Решения

Эта задача имеет тип `code`: она меняет скилл, поэтому исключение docs-only к ней не применяется. Карточка была остановлена, продолжение — после ответа владельца.

Публикация — `git push -u origin docs/c03-docs-only-exception`. Скилл из-за этой команды не менялся: на момент пуша upstream ветки указывал на `origin/main`.

`protocol/version.json`, `scripts/`, прочие файлы `.cursor/`, `README.md`, `protocol/roles.md`, `protocol/handoff.md`, `protocol/verdict.md`, `LICENSE`, `PROVENANCE.md` не менялись. `AGENTS.md` не создавался.

## Проверки

| Проверка | Результат |
|---|---|
| `git diff --cached --check` до снимка | exit 0 |
| `git diff --cached --stat` до снимка | `protocol/cycle.md`, `.cursor/skills/task-start/SKILL.md`: 2 files changed, 15 insertions(+), 1 deletion(-), exit 0 |
| `git diff --cached --numstat` скилла | `1	1` — одна строка шага 2 |
| Поиск маркеров автозакрытия Issue и типовых секретов в staged diff до снимка | совпадений нет |
| Выражения PowerShell `^{...}` | в командах этой задачи не использовались |
| `scripts/verify/collect-verifier-pack.ps1 -Issue 6` | exit 0. Пакет без этого снимка: `name_status_count` 2, `has_unstaged_changes` no, `diff_mode` full, `origin_main_sha` `7cd190b7d00da7e460eaf2ce03de50ed297a31eb` |

### verifier (субагент)

Запущено. Сбор пакета — строка таблицы выше.

Прогон по пакету Issue #6: субагент вернул отчёт. Input fingerprint совпал с пакетом (`branch` `docs/c03-docs-only-exception`, `name_status_count` 2, `has_unstaged_changes` no, `diff_mode` full). Подтвердил раздел «Исключение docs-only» и одну заменённую строку шага 2. Снимок в пакете отсутствовал — это отмечено как пробел пакета. PR на момент прогона не существовал и не засчитывался. Чужих путей в пакете не было. Сверка родителем вместо субагента не оформлялась.

## Блокеры

Нет блокера публикации.

## Следующий шаг

Ревью Perplexity по handoff и merge проверенного SHA, если блокирующих замечаний нет.
