# PROVENANCE

## Источник

- Репозиторий: `Lex226/1c-document-collection`
- Коммит: `54a6f2d0203bc0ad3bd5914271ab3793cd722a8c`
- База этой ветки: `origin/main` `0d1bd9e0ac4ac0ca8cd2088f344fea8801c5e89c`

## Файлы

| Путь здесь | Изменение относительно блоба источника |
|---|---|
| `.cursor/agents/verifier.md` | Имя репозитория заменено на «this repository». Ссылки на ADR источника ведут на `protocol/roles.md`, `protocol/cycle.md`, `protocol/handoff.md`, `protocol/verdict.md`. |
| `.cursor/skills/task-card/SKILL.md` | Фраза про идентификаторы требований и метаданные предметной области вместо формулировки источника. |
| `.cursor/skills/task-card/task-card.md` | Без изменений. |
| `.cursor/skills/task-start/SKILL.md` | Чтение `protocol/` и `AGENTS.md`, если он есть. Снимок сессии ссылается на `protocol/cycle.md`. Публикация ссылается на `protocol/roles.md`. |
| `.cursor/skills/review-handoff/SKILL.md` | В шаблоне `<owner>/<repo>`. Ссылки на правила ведут на `protocol/handoff.md` и `protocol/roles.md`. |
| `.cursor/hooks.json` | Без изменений. |
| `scripts/hooks/guard-git.ps1` | Без изменений. |
| `scripts/hooks/tests/guard-git.cases.json` | В трёх командах слаг репозитория-источника заменён на `o/r`. |
| `scripts/hooks/tests/run-guard-tests.ps1` | Без изменений. |
| `scripts/verify/collect-verifier-pack.ps1` | Без изменений. |
| `scripts/verify/tests/test-verifier-pack.ps1` | Без изменений. |
| `protocol/roles.md` | Новый текст правила публикации. |
| `protocol/cycle.md` | Новый текст цикла и раздела «Снимок сессии». |
| `protocol/handoff.md` | Новый текст передачи на ревью. |
| `protocol/verdict.md` | Новый текст вердикта по SHA. |
| `protocol/version.json` | `{"protocol_version": "0.1.0-experimental"}` |
| `README.md` | Назначение, состав, ручное копирование, ограничения. |
| `sessions/2026-11-09-c01-import.md` | Снимок этой задачи. |

Не копировались `.cursor/rules/project.mdc`, `AGENTS.md`, `adr/`, `agent_docs/` и `sessions/` источника.

## Имя ADR-0003

В причинах отказа `scripts/hooks/guard-git.ps1` остаётся текст ADR-0003. Комментарии того же файла упоминают ADR-0005. Это имена правил источника. Скрипт не менялся. В этом репозитории правило публикации записано в `protocol/roles.md`, цикл и handoff — в `protocol/cycle.md` и `protocol/handoff.md`.

## Синтетические адреса

`scripts/verify/tests/test-verifier-pack.ps1` скопирован байт в байт. Строки `c04@test.local` и `c08@test.local` — значения `git -c user.email` для временного репозитория теста. Это не адреса людей. Шаблон поиска этой задачи их не требует объяснять как путь или имя проекта; они оставлены, потому что файл не редактируется.

## Поиск

Команда: `git grep -n -i -E` с шаблоном `1c`, кириллическое `1с`, `document-collection`, `C:\Users`.

Совпадения, которые даёт этот файл:

- Имя репозитория-источника в разделе «Источник». Это запись происхождения.
- Полный SHA базы `0d1bd9e0ac4ac0ca8cd2088f344fea8801c5e89c`: внутри 40 hex есть последовательность `1c`. Это не имя проекта и не путь.
- Полный SHA источника `54a6f2d0203bc0ad3bd5914271ab3793cd722a8c` в шаблон по этой последовательности не входит; он записан как идентификатор коммита.

Фикстуры матрицы guard (`o/r`, подписи кейсов, синтетические пути к `Program Files`) в шаблон не входят.

Список совпадений до снимка сессии:

1. `PROVENANCE.md:5` — слаг репозитория-источника, запись происхождения.
2. `PROVENANCE.md:7` — полный SHA базы; совпадение внутри 40 hex.
3. `PROVENANCE.md:44` — в строке назван сам шаблон поиска, включая префикс пути профиля. Это текст шаблона, не каталог.
4. `PROVENANCE.md:49` — тот же SHA базы и пояснение про последовательность внутри hex.
5. `sessions/2026-11-09-c01-import.md:13` — тот же полный SHA базы, совпадение внутри 40 hex.

## C13: scripts/labels/apply-labels.ps1

- Репозиторий: `Lex226/github-playbook`
- Путь: `scripts/apply-labels.ps1`
- Коммит: `eeffb66e9669e933dab0f1ea816a59d802f3055a`
- Blob: `fa01bdf2e597b404bfd221d1daa97c71c5437fea`

Изменения относительно блоба источника:

- Параметр `-LabelsFile` не перенесён. Набор читается как `standards/labels.json` из `Lex226/github-playbook` на коммите `-LabelsRef`.
- `-LabelsRef` обязателен, без значения по умолчанию. Принимается только полный SHA `^[0-9a-f]{40}$`. Если на этом SHA нет `standards/labels.json`, выход ненулевой.
- Добавлен `-WhatIf`: собственный `[switch]`, без `CmdletBinding` и без `ShouldProcess`. В этом режиме только чтение. По каждой метке набора печатается «создать», «обновить» или «без изменений».
- Параметр `-RemoveExtra` и цикл удаления меток сняты. Метки репозитория вне набора не удаляются.
- Ответ `contents` декодируется из base64 в UTF-8.
- Пустое описание и `null` считаются равными.
- Если список меток репозитория достиг лимита 200, печатается предупреждение, что список может быть неполным.
- Ошибка `gh` пишется в поток ошибок через `[Console]::Error`, не через `Write-Error`.
- Файл скрипта — UTF-8 с BOM, Windows PowerShell 5.1, в том же стиле, что `scripts/verify/collect-verifier-pack.ps1`.