# agentic-protocol

Shared protocol for agent task, report, and review handoff.

## Назначение

Каноническая копия движка Cursor для согласованной задачи: карточка, предварительная сверка скоупа, локальный guard команд git/gh и промпт передачи на ревью. Версия `0.1.0-experimental` записана в `protocol/version.json`.

## Состав

- `.cursor/agents/verifier.md` — субагент предварительной сверки
- `.cursor/skills/task-card`, `task-start`, `review-handoff`
- `.cursor/hooks.json` и `scripts/hooks/` — guard и его тесты
- `scripts/verify/` — сбор пакета verifier и тесты сборщика
- `protocol/` — роли, цикл, handoff, вердикт по SHA

Общие правила репозиториев: [конституция github-playbook](https://github.com/Lex226/github-playbook/blob/main/standards/00-constitution.md).

## Как подключить

Подключение ручное: скопировать состав выше в целевой репозиторий с закреплённого коммита или тега этого репозитория. Движок не подставляет имя целевого проекта. В промпте handoff `<owner>/<repo>` заполняется при выпуске.

## Ограничения

- Guard проверяет командную строку в IDE. Это не изоляция: алиасы git, тело файла у `powershell -File` и вложенные подстановки вроде `$(git …)` он не разбирает как отдельные команды.
- Ответ `ask` может не показать запрос. Причина не выяснена.
- Поведение `deny` и `failClosed` в этом импорте не проверено. В `.cursor/hooks.json` стоит `failClosed: true`, как в источнике.
- Строки причин в `scripts/hooks/guard-git.ps1` называют ADR-0003. Это имя правила в репозитории-источнике. В этом репозитории то же правило записано в `protocol/roles.md`.
- Разбиение цепочек команд учитывает простые кавычки приблизительно. Упоминание git или gh в середине команды даёт `ask`, в том числе для безобидных вызовов вроде `Get-Command git`.
- `scripts/hooks/guard-git.ps1` и матрица его кейсов меняются только после реального инцидента или явного решения владельца.
- Guard не заменяет защиту ветки на GitHub.
