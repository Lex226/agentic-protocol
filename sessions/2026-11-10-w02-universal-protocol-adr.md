---
date: 2026-11-10
task: w02-universal-protocol-adr
refs: "#23"
author: Cursor
---

# W02: универсальный протокол, ADR

## Задача / ветка / commit

- Issue #23, `Refs #23`. Тип `docs-only`. Карточка выведена и работа продолжена без остановки на «да»: тип в брифе `docs-only`, скоуп по файлам задан в Issue и брифе, меняются только `*.md` вне `.cursor/` и этот снимок, не затрагиваются `scripts/`, `.cursor/`, `protocol/version.json`, LICENSE, теги и настройки GitHub, не меняются `protocol/roles.md`, `verdict.md`, `handoff.md`.
- Ветка `docs/w02-universal-protocol-adr` от `origin/main` `a6f2c0e4ccf1b0a3dee55b27dd368b0b7fab093f`. Worktree `..\agentic-protocol-w02`. Дерево C10 этим снимком не менялось.
- На старте `git status` дерева C10 был чистым (`fix/c10-gh-big-stderr-timeout`). Каталога `adr/` на `main` не было.
- Полный SHA commit — в handoff. Этот текст входит в тот commit.

## Сделано

`adr/ADR-0001-template.md` — шаблон по Правилу 3 конституции: `## Контекст`, `## Принятое решение`, строка `Статус: Proposed`. Шаблон не является решением.

`adr/ADR-0002-universal-protocol.md` — статус Proposed. Слои, роли, `reviewer.independence`, метки `scripts/labels/` и поля `labels.source` + `labels.ref`, развёртывание, первый адаптер `protocol/perplexity/`, решение оставить `1c-repo-template` и `scripts/sync-agent-rules.ps1`, план C13–C16. Решения владельца 1–3 из #23 приведены по смыслу дословно. #24 из-за имён полей не переписывается.

`README.md`, раздел «Состав»: строка о каталоге `adr/`.

`CHANGELOG.md` не менялся.

## Решения

- `reviewer.independence: internal` не действует, пока отдельная C16 не изменит `protocol/roles.md`. Merge при internal делает владелец, вердикт помечается «ревью внутреннее, независимость снижена».
- Имена для C13 не заменены: каталог `scripts/labels/`, файл `scripts/labels/apply-labels.ps1`, поля `labels.source` и `labels.ref`.
- `1c-repo-template` (main `1481c514f576c2c8779829bc23a09c30ed0209a6`) и `sync-agent-rules.ps1` оставлены. Протокол их не вызывает.
- `protocol/perplexity/` остаётся первым адаптером на текущем пути до C15.
- Статус Proposed не переводит решение в Accepted и не меняет поведение движка.

## Проверки

| Проверка | Результат |
|---|---|
| `git diff --check` по индексу до снимка | exit 0. Предупреждение Git: LF будет заменён на CRLF при следующем касании `adr/ADR-0001-template.md` и `adr/ADR-0002-universal-protocol.md` |
| `git diff --cached --name-status origin/main` до снимка | `M README.md`, `A adr/ADR-0001-template.md`, `A adr/ADR-0002-universal-protocol.md` |
| `git diff --cached --name-status origin/main` со снимком | `M README.md`, `A adr/ADR-0001-template.md`, `A adr/ADR-0002-universal-protocol.md`, `A` этот файл |
| ключевые слова автозакрытия Issue в diff | совпадений нет |
| `CHANGELOG.md`, `protocol/*`, `scripts/`, `.cursor/` | не в diff |

Сверка утверждений ADR-0002:

| Утверждение | Файл | Итог |
|---|---|---|
| Сейчас Cursor не мёржит; независимое ревью и merge делает Perplexity | `protocol/roles.md` | совпадает |
| `internal` текущий `roles.md` не допускает и до C16 не применяется | `protocol/roles.md` | совпадает |
| Действующий цикл: независимое ревью Perplexity, merge проверенного SHA | `protocol/cycle.md` | совпадает |
| Verifier не заменяет ревью | `protocol/cycle.md` | совпадает |
| Merge делает ревьюер и только SHA из handoff; на private/Free протокол не требует required checks | `protocol/platform.md` | совпадает с действующим `external`. Смена актора при `internal` в силу не введена, она названа работой C16 вместе с этой фразой |
| Отсутствие CI не считается успешным CI; handoff несёт полный SHA | `protocol/handoff.md`, `protocol/verdict.md` | совпадает |
| Независимое ревью и merge Perplexity, Cursor без merge и без auto-merge | `1c-document-collection` `adr/ADR-0003-agent-pr-workflow.md` | совпадает с `external` |
| Слои v0 сохраняются; verifier не независимое ревью; хуки не заменяют защиту ветки | `1c-document-collection` `adr/ADR-0005-cursor-engine.md` | совпадает |
| `protocol/perplexity/` остаётся источником текста, пока каталог не перенесён | `protocol/perplexity/README.md` | совпадает |

Таблица сверки выше собрана автором снимка по прочитанным файлам. Субагент её не подтверждает и не заменяет.

### verifier (субагент)

Первый прогон, пакет `scripts/verify/collect-verifier-pack.ps1 -Issue 23`, exit 0. Fingerprint: `branch` `docs/w02-universal-protocol-adr`, `origin_main_sha` `a6f2c0e4ccf1b0a3dee55b27dd368b0b7fab093f`, `name_status_count` 4, `has_unstaged_changes` no, `diff_mode` full. Субагент подтвердил четыре markdown-файла скоупа, секции шаблона, пункт 2 #23, решения владельца, строку `README`, снимок и то, что `internal` не вводится в `roles.md`. Не засчитал PR, handoff и protocol-check: их в пакете нет. Не читал ADR-0003, ADR-0005, `verdict.md`, `handoff.md` и тело #24. Отметил два статуса: YAML `status: draft` и строка `Статус: Proposed`.

После этого прогона YAML-фронтматтер снят в обоих ADR, в ADR-0002 записано, почему строка статуса одна. Этот абзац заменяет заглушку первого пакета. Второй прогон смотрит уже этот текст. Сверка родителем вместо субагента не оформлялась.

Второй прогон смотрел пакет уже без YAML `status: draft` и с абзацем первого прогона. Fingerprint: `branch` `docs/w02-universal-protocol-adr`, `origin_main_sha` `a6f2c0e4ccf1b0a3dee55b27dd368b0b7fab093f`, `name_status_count` 4, `has_unstaged_changes` no, `diff_mode` full. Подтвердил одну строку `Статус: Proposed`, скоуп #23, строку README и то, что `internal` в `roles.md` не включён. Прочитал `cycle.md`, `platform.md`, `handoff.md` и `verdict.md`: действующий `external` им не противоречит. Не засчитал PR, handoff, protocol-check и независимое ревью Perplexity. Не читал ADR-0003, ADR-0005, `protocol/perplexity/README.md`, тело #24 и страницы cursor.com. Этот абзац дописан после второго прогона и в тот пакет не входил.

## Блокеры

Нет блокера публикации. PR, handoff и полный SHA на момент первого абзаца этого раздела ещё не существуют: commit не сделан.

## Следующий шаг

Ревью Perplexity по handoff и merge проверенного SHA, если блокирующих замечаний нет. После merge можно стартовать C13 (#24) по тексту этого Issue. C16 не стартовать вместе с C13: #24 не расширяет права сверх меток. Workflow `release` не запускается: `protocol/version.json` не менялся.

---
Perplexity 10.11.2026, сессия C12
- PR #26 (C12) смёржен: HEAD d36c354, merge a6f2c0e4ccf1b0a3dee55b27dd368b0b7fab093f, check success (run 42797499142).
- PR #25 (527adf8, merge 76ac75f) смёржен владельцем без handoff; проверен постфактум, принят как есть.
- #21 закрыт (completed) после комментария о приёмке issuecomment-6764846385.
- Space: заменить строку «Разрешено только» по main a6f2c0e; personal — без изменений.
- Трек P: W02 #23 → C13 #24. Трек E: C10 #19 (в работе) → C11 #20 → C09 #16.
- Кандидаты для conventions-auditor: дубль абзаца «Если субагент недоступен…» в protocol/cycle.md; .gitattributes LF/CRLF; в protocol/perplexity/README.md не указана единица длины (кодовые точки vs UTF-16).
---
