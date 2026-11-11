---
date: 2026-11-11
task: c20-cycle-dedup
refs: "#38"
author: Cursor
---

# C20: cycle.md без дубля абзаца о недоступном verifier

## Задача / ветка / commit

- Issue #38, `Refs #38`. Тип `docs-only`. Карточка выведена. Остановка на «да» не нужна: одновременно выполнены все условия раздела «Исключение docs-only» в `protocol/cycle.md` (тип `docs-only`; скоуп по пунктам задан в Issue #38 и брифе; меняются только `protocol/cycle.md`, `CHANGELOG.md` и этот снимок; не затрагиваются `scripts/`, `.cursor/`, `protocol/version.json`, LICENSE, теги и настройки GitHub; не меняются `protocol/roles.md`, `verdict.md`, `handoff.md`).
- Ветка `docs/c20-cycle-dedup` от `origin/main` `12f6f86752242c2e5c5976ce5133c1c98d0b1d1b`. Перед созданием ветки дерево было чистым. `git fetch origin`. Факт `origin/main` совпал с ожидаемым SHA. Blob `origin/main:protocol/cycle.md` = `fd711b94ade4ea2f9a3c8d4f17da68fc0fc83a7a`.
- `AGENTS.md` в репозитории нет. Прочитаны `protocol/cycle.md`, `protocol/roles.md`, `protocol/handoff.md`, `protocol/verdict.md`, `README.md`, Issue #38 и последний снимок `sessions/2026-11-10-c19-readme-version.md`.
- `git switch -c docs/c20-cycle-dedup origin/main` поставил upstream на `origin/main`. Upstream снят (`git branch --unset-upstream`), чтобы публикация не целилась в `main`.
- Этот текст входит в commit ветки. Полный SHA — в handoff.

## Сделано

`protocol/cycle.md`. Удалён отдельный абзац после «Verifier — предварительная сверка…» и перед «Если ревью оставило замечания…»: «Если субагент недоступен, в отчёте и handoff пишется `verifier (субагент): не запущено` с причиной. Сверка родителем не подставляется и так не называется.» Вместе с ним убрана одна пустая строка. Шаг 5 нумерованного списка не менялся.

`CHANGELOG.md`, под `## [Unreleased]`, строка над C19: `C20 — cycle.md без дубля абзаца о недоступном verifier, Issue #38.`

## Решения

Шаг 5 оставлен: фраза `verifier (субагент): не запущено` остаётся в нём. `core.autocrlf` не менялся. Файлы скоупа — UTF-8 без BOM. Метки Issue и прочие настройки GitHub не менялись. Кандидаты conventions-auditor (LF/CRLF и прочее из скоупа #31) не правились.

## Проверки

Среда: Windows PowerShell 5.1.

| Проверка | Результат |
|---|---|
| `Select-String -Path protocol/cycle.md -SimpleMatch 'verifier (субагент): не запущено'` | 1 совпадение, строка 9, шаг 5 |
| `git diff origin/main -- protocol/cycle.md` | только удалённые строки: абзац и одна пустая строка. Вывод ниже |
| `git diff --check` и `git diff --cached --check` | exit 0, без conflict markers. Предупреждение autocrlf на stderr при `git add`, индекс `i/lf` |
| `git diff --stat origin/main` и `git diff --cached --stat` | до абзаца verifier: 3 files changed, 70 insertions(+), 2 deletions(-). Три пути: `CHANGELOG.md`, `protocol/cycle.md`, `sessions/2026-11-11-c20-cycle-dedup.md` |

`Select-String`:

```
9:5. Verifier: родитель собирает пакет и передаёт его субагенту. Если субагент недоступен, в отчёте и handoff пишется `verifier (субагент): не запущено` с причиной. Сверка родителем не подставляется и так не называется.
```

`git diff origin/main -- protocol/cycle.md`:

```
diff --git a/protocol/cycle.md b/protocol/cycle.md
index fd711b9..6b43cdc 100644
--- a/protocol/cycle.md
+++ b/protocol/cycle.md
@@ -18,8 +18,6 @@

 Verifier — предварительная сверка на стороне Cursor. Он не заменяет ревью и merge из `protocol/roles.md`. Родитель собирает пакет командой `scripts/verify/collect-verifier-pack.ps1`. Субагент читает пакет и перечисленные файлы и не запускает git. С параметром `-Issue` и origin на GitHub в пакет входят заголовок и тело Issue; ошибка `gh` останавливает сбор. Без GitHub-origin `gh` не вызывается, в секции скоупа остаётся заглушка.

-Если субагент недоступен, в отчёте и handoff пишется `verifier (субагент): не запущено` с причиной. Сверка родителем не подставляется и так не называется.
-
 Если ревью оставило замечания, исправление — новый commit в ту же ветку, push и новый handoff. Предыдущий промпт недействителен.

 ## Исключение docs-only
```

### verifier (субагент)

Запущено. Сбор `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify/collect-verifier-pack.ps1 -Issue 38` после staging, до этого абзаца: exit 0. Fingerprint пакета: `branch` `docs/c20-cycle-dedup`, `origin_main_sha` `12f6f86752242c2e5c5976ce5133c1c98d0b1d1b`, `name_status_count` 3, `has_unstaged_changes` no, `diff_mode` full, `sessions_count` 1, `sessions_paths` `sessions/2026-11-11-c20-cycle-dedup.md`. `git diff --cached --stat origin/main` до этого абзаца: 3 files changed, 70 insertions(+), 2 deletions(-).

Субагент вернул отчёт. Input fingerprint совпал со всеми семью полями. Подтвердил: diff `protocol/cycle.md` только удаления (абзац и одна пустая строка), шаг 5 не в хунке, фраза `verifier (субагент): не запущено` один раз в строке 9, строка C20 над C19, этот снимок с frontmatter `date`/`task`/`refs`/`author: Cursor`, три пути скоупа, `has_unstaged_changes: no`. `git diff --check` субагент заново не запускал и в отчёт не засчитал. Claimed but missing: нет. PR и handoff в пакет не входили: проверка до commit. Out of scope: нет. Git субагент не запускал. В снимке внутри пакета этого абзаца не было. Абзац дописан после прогона. Сверка родителем вместо субагента не оформлялась.

## Блокеры

Нет блокера публикации.

## Следующий шаг

Ревью Perplexity по handoff и merge проверенного SHA, если блокирующих замечаний нет. Этот pull request не выпускает релиз: `protocol/version.json` не менялся.
