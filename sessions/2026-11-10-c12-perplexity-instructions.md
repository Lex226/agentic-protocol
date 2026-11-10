---
date: 2026-11-10
task: c12-perplexity-instructions
refs: "#21"
author: Cursor
---

# C12: инструкции Perplexity и закрытие Issue и PR

## Задача / ветка / commit

- Issue #21, `Refs #21`. Тип `code`. Карточка выведена, владелец ответил «да» 10.11.2026. Меняется `protocol/roles.md`, исключение docs-only не применяется.
- Ветка `docs/c12-perplexity-project-labels`. Работа в worktree `..\agentic-protocol-c12`. Дерево `fix/c10-gh-big-stderr-timeout` не менялось.
- Уже опубликованный commit ветки: `527adf894c4e2b244adc15e2d40f0b567b31a643` (только `protocol/perplexity/project.md`). Он вошёл в `main` merge-коммитом PR #25 `76ac75f2886ed192f413f080221aa542adffe766`. Деревья `527adf8` и `origin/main` совпадают (`git diff --stat 527adf8..origin/main` пустой).
- `git merge origin/main` отклонён hook (ADR-0003). Новый commit — потомок `527adf8`. Этот текст входит в него. Полный SHA — в handoff.
- `AGENTS.md` в репозитории нет.

## Сделано

`protocol/perplexity/project.md`, строка «Разрешено только»: добавлено «закрытие PR без merge — только по прямому поручению владельца, после комментария с причиной; ветку не удалять» (комментарий владельца issuecomment-6763778574). Остальной текст файла не менялся.

`protocol/roles.md`: после существующих абзацев раздела «Публикация» добавлены два правила. Текст разделов «Кто пишет» и «Публикация» выше не менялся. Закрытие Issue (`state_reason` completed) — только по прямому поручению владельца и после комментария о приёмке со ссылкой на merge commit. Merge ≠ приёмка ≠ закрытие Issue. Закрытие PR без merge — только по прямому поручению владельца, после комментария с причиной; ветку не удалять.

`protocol/perplexity/personal.md`: побайтный перенос из issuecomment-6764044663. Строки-маркеры `----- BEGIN personal.md -----` и `----- END personal.md -----` в файл не входят. Не входят и переводы строк, которыми заканчиваются сами строки-маркеры.

`protocol/perplexity/README.md`: источник истины, порядок Issue → PR → merge → владелец вставляет текст в Space, лимиты 8000 и 1500 символов.

`CHANGELOG.md`, `## [Unreleased]`: запись C12, Issue #21.

## Решения

Разница 5322 / 5359. Текст Space, вставленный владельцем 10.11.2026, сравнивался с blob `527adf8:protocol/perplexity/project.md`. После отбрасывания завершающего LF blob совпал с текстом Space: 5321 символ, `equal_space=True`. Blob с завершающим LF — 5322 символа. Число 5359 из Issue #21 — тот же текст без завершающего LF, но со старой строкой меток. Замена этой строки в `527adf8` (решение владельца 10.11.2026): 146 символов → 108, минус 38. `5321 + 38 = 5359`. `5322 = 5359 − 38 + 1` завершающий LF. Содержательной разницы со вставленным текстом Space, кроме этого LF, нет.

Длина `personal.md` в проверке — число кодовых точек Unicode (и `StringInfo.LengthInTextElements`): 1385. `String.Length` в .NET равен 1388: три символа футера (U+1F7E2, U+1F7E1, U+1F534) занимают по суррогатной паре. Файл без BOM, без CR, 14 LF, без завершающего LF. SHA-256 `e17649dcbce3ee1248dc5769247afa552cde2e4eb1f4c38345ca1c9356daf543`.

Пишет один участник. `scripts/`, `.cursor/`, `protocol/version.json`, `protocol/cycle.md` не менялись.

## Проверки

| Проверка | Результат |
|---|---|
| Длина `project.md` | LF-текст 5433 символа, `le8000=True`. Рабочая копия CRLF: `workdir_chars=5512` |
| Длина `personal.md` | `utf8_bytes=2324`, `utf16=1388`, `codepoints=1385`, `text_elements=1385`, `le1500=True` |
| Diff Space против blob `527adf8` | `space_lf_chars=5321`, `blob_chars=5322`, `equal_space=True` без завершающего LF; восстановление старой строки меток даёт `restored_no_final=5359` |
| `git diff --stat 527adf8..origin/main` | пустой. `origin/main` = `76ac75f2886ed192f413f080221aa542adffe766` |
| `git diff --cached --check` | exit 0. Предупреждение Git: LF будет заменён на CRLF при следующем касании `protocol/perplexity/README.md`, `protocol/perplexity/personal.md` и этого снимка |
| `git diff --cached --stat` до абзаца verifier | 6 files changed, 87 insertions(+), 1 deletion(-). `CHANGELOG.md`, `protocol/perplexity/README.md`, `protocol/perplexity/personal.md`, `protocol/perplexity/project.md`, `protocol/roles.md`, этот снимок |
| `git diff --cached --name-status origin/main` | M `CHANGELOG.md`, A `README.md`, A `personal.md`, M `project.md`, M `protocol/roles.md`, A этот снимок |
| `Closes` / `Fixes` / `Resolves` и типовые секреты в staged diff | совпадений нет |
| `protocol-check` на HEAD PR | на момент снимка не запущено: push ещё не сделан |
| Тесты `scripts/` | не запущено: вне скоупа, скрипты не меняются |

### verifier (субагент)

Запущено дважды. Сбор оба раза: `scripts/verify/collect-verifier-pack.ps1 -Issue 21`, exit 0. Fingerprint обоих пакетов: `branch` `docs/c12-perplexity-project-labels`, `origin_main_sha` `76ac75f2886ed192f413f080221aa542adffe766`, `name_status_count` 6, `has_unstaged_changes` no, `diff_mode` full, `sessions_count` 1, `sessions_paths` `sessions/2026-11-10-c12-perplexity-instructions.md`.

Первый прогон подтвердил правила закрытия Issue и PR, README, CHANGELOG и лимиты длин. Отметил, что в снимке не было разделов «Блокеры» и «Следующий шаг». Они добавлены до второго сбора. PR, handoff и `protocol-check` не засчитывал: push ещё не был сделан.

Второй прогон смотрел пакет уже с этими разделами. `git diff --cached --stat` до этого абзаца: 6 files changed, 87 insertions(+), 1 deletion(-). Подтвердил разделы «Блокеры» и «Следующий шаг» и отсутствие посторонних путей. Побайтное совпадение `personal.md` с телом issuecomment-6764044663 не подтвердил: тела комментария в пакете нет. Diff текста Space против blob в пакете не было; строка `equal_space=True` в снимке — результат команды родителя, не вывод субагента. PR, handoff и `protocol-check` снова не засчитывал. Этот абзац дописан после второго прогона. Сверка родителем вместо субагента не оформлялась.

## Блокеры

Нет блокера публикации. PR с `Refs #21`, handoff с полным SHA и `protocol-check` на момент этого абзаца ещё не существуют: commit и push не сделаны.

## Следующий шаг

Ревью Perplexity по handoff и merge проверенного SHA, если блокирующих замечаний нет. После merge владелец вставляет тексты в Space. Workflow `release` не запускается: `protocol/version.json` не менялся.
