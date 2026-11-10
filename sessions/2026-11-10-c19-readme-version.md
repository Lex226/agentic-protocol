---
date: 2026-11-10
task: c19-readme-version
refs: "#36"
author: Cursor
---

# C19: README без зашитого номера версии

## Задача / ветка / commit

- Issue #36, `Refs #36`. Тип `docs-only`. Карточка выведена. Остановка на «да» не нужна: одновременно выполнены все условия раздела «Исключение docs-only» в `protocol/cycle.md` (тип `docs-only`; скоуп по пунктам задан в Issue #36 и брифе; меняются только `README.md`, `CHANGELOG.md` и этот снимок; не затрагиваются `scripts/`, `.cursor/`, `protocol/version.json`, LICENSE, теги и настройки GitHub; не меняются `protocol/roles.md`, `verdict.md`, `handoff.md`).
- Ветка `docs/c19-readme-version` от `origin/main` `cb387cd748bc6d42c7fb6516c6e69d8a17b9e18f`. Перед созданием ветки дерево было чистым. `git fetch origin`. Факт `origin/main` совпал с ожидаемым SHA.
- `AGENTS.md` в репозитории нет.
- Метки #36: `documentation`, `priority:medium`, `stage:in-progress`. Метка `stage:*` одна. `stage:intake` снята (`gh issue edit 36`, exit 0).
- Upstream после создания ветки снят. Этот текст входит в commit ветки. Полный SHA — в handoff.

## Сделано

`README.md`, «Назначение». Номер `0.2.0-experimental` убран. Версия — ссылка на `protocol/version.json` как единственный источник.

`README.md`, «Как подключить». Копировать с тега `v<protocol_version>`. Актуальный — последний Release; пример — `v0.3.0-experimental`. Утверждение «Тег и значение `protocol_version` в `protocol/version.json` совпадают» сохранено. Остальные предложения абзаца не менялись.

`CHANGELOG.md`, под `## [Unreleased]` одна строка: `C19 — README без зашитого номера версии, тег подключения по protocol/version.json, Issue #36.` Секция `## [0.3.0-experimental]` и ниже не менялись.

## Решения

Разделы README «Состав», «Как выпускается релиз», «Работа без серверной защиты» и «Ограничения» не менялись. `protocol/version.json` остаётся `0.3.0-experimental`. `release.yml`, теги и Release не менялись. C17 #31 и кандидаты conventions-auditor не правились.

Оба файла записаны UTF-8 без BOM, только LF. В индексе оба `i/lf`. После первой записи рабочая копия `README.md` была CRLF (70 байт CR); перед `git add` она переписана на LF.

## Проверки

Среда: Windows PowerShell 5.1.20348.4294.

| Проверка | Результат |
|---|---|
| `git grep -n "0.2.0-experimental" -- README.md` | вывод пустой, exit 1 |
| `git ls-files --eol -- README.md CHANGELOG.md` после `git add` | оба `i/lf` `w/lf`. Вывод ниже |
| `git diff --cached origin/main -- README.md CHANGELOG.md` | вывод ниже |
| `git diff --cached --check` | exit 0, вывода нет. Индекс: `README.md`, `CHANGELOG.md` и этот снимок |
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/hooks/tests/run-guard-tests.ps1` | exit 0. `RESULT: 57 passed / 0 failed (total 57)` |
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify/tests/test-verifier-pack.ps1` | exit 0. `RESULT: 16 passed / 0 failed (total 16)` |
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/labels/tests/test-apply-labels.ps1` | exit 0. `RESULT: 12 passed / 0 failed (total 12)` |
| pwsh 7 | не запущено: pwsh не найден |
| метки #36 | `stage:intake` снята, `stage:in-progress` стоит |

`git ls-files --eol`:

```
i/lf    w/lf    attr/                 	CHANGELOG.md
i/lf    w/lf    attr/                 	README.md
```

`git diff --cached origin/main -- README.md CHANGELOG.md`:

```
diff --git a/CHANGELOG.md b/CHANGELOG.md
index 3a5840b..67ef5d4 100644
--- a/CHANGELOG.md
+++ b/CHANGELOG.md
@@ -2,6 +2,8 @@

 ## [Unreleased]

+- C19 — README без зашитого номера версии, тег подключения по protocol/version.json, Issue #36.
+
 ## [0.3.0-experimental]

 - C13 — scripts/labels/apply-labels.ps1: аддитивный накат меток, -WhatIf, -LabelsRef; разрешение в roles.md, Issue #24.
diff --git a/README.md b/README.md
index ab94429..2427523 100644
--- a/README.md
+++ b/README.md
@@ -4,7 +4,7 @@ Shared protocol for agent task, report, and review handoff.

 ## Назначение

-Каноническая копия движка Cursor для согласованной задачи: карточка, предварительная сверка скоупа, локальный guard команд git/gh и промпт передачи на ревью. Версия `0.2.0-experimental` записана в `protocol/version.json`.
+Каноническая копия движка Cursor для согласованной задачи: карточка, предварительная сверка скоупа, локальный guard команд git/gh и промпт передачи на ревью. Версия — ссылка на `protocol/version.json` как единственный источник.

 ## Состав

@@ -22,7 +22,7 @@ Shared protocol for agent task, report, and review handoff.

 ## Как подключить

-Подключение ручное: скопировать состав выше в целевой репозиторий с тега `v0.2.0-experimental`. Тег и значение `protocol_version` в `protocol/version.json` совпадают. Движок не подставляет имя целевого проекта. В промпте handoff `<owner>/<repo>` заполняется при выпуске. `.github/workflows/` потребителю не копируются.
+Подключение ручное: скопировать состав выше в целевой репозиторий с тега `v<protocol_version>`. Актуальный — последний Release; пример — `v0.3.0-experimental`. Тег и значение `protocol_version` в `protocol/version.json` совпадают. Движок не подставляет имя целевого проекта. В промпте handoff `<owner>/<repo>` заполняется при выпуске. `.github/workflows/` потребителю не копируются.

 ## Как выпускается релиз
```

### verifier (субагент)

Запущено. Сбор `scripts/verify/collect-verifier-pack.ps1 -Issue 36` после staging, до этого абзаца: exit 0. Fingerprint пакета: `branch` `docs/c19-readme-version`, `origin_main_sha` `cb387cd748bc6d42c7fb6516c6e69d8a17b9e18f`, `name_status_count` 3, `has_unstaged_changes` no, `diff_mode` full, `sessions_count` 1, `sessions_paths` `sessions/2026-11-10-c19-readme-version.md`. `git diff --cached --stat` до этого абзаца: 3 files changed, 116 insertions(+), 2 deletions(-).

Субагент вернул отчёт. Input fingerprint совпал со всеми семью полями. Подтвердил три пути скоупа, снятие `0.2.0-experimental` в «Назначение», тег `v<protocol_version>` и пример `v0.3.0-experimental` в «Как подключить», сохранённое совпадение тега и `protocol_version`, одну строку C19 под `## [Unreleased]`, неизменность секции `## [0.3.0-experimental]` и остальных разделов README, этот снимок, `i/lf` и `git diff --cached --check` exit 0. Claimed but missing: check run `check`, PR и handoff — их ещё не было. Out of scope: нет. Git и тесты субагент не запускал. В снимке внутри пакета этого абзаца не было. Абзац дописан после прогона. Сверка родителем вместо субагента не оформлялась.

## Блокеры

Нет блокера публикации.

## Следующий шаг

Ревью Perplexity по handoff и merge проверенного SHA, если блокирующих замечаний нет. Этот pull request не выпускает релиз: `protocol/version.json` и секции релизов CHANGELOG не менялись.

---
Perplexity 10.11.2026
- C18 #34 принят и закрыт: PR #35, merge cb387cd, Release v0.3.0-experimental (prerelease),
  приёмка issuecomment-6768858604; метки #34: stage:in-progress → stage:release.
- Владелец: новый узкий репозиторий для отчёта БДР из 1c-alfa-auto-devlab
  (objects/common/budget-dr-report). Переносим описание, инструменты, .erf,
  v8unpack/, derived/. ADR и git-историю не переносим. Протокол подключается
  с тега после C19.
- Кандидаты conventions-auditor: метки stage:done нет в standards/labels.json;
  github-playbook #3 и #4 без priority/stage.
---
