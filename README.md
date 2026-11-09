# agentic-protocol

Shared protocol for agent task, report, and review handoff.

## Назначение

Каноническая копия движка Cursor для согласованной задачи: карточка, предварительная сверка скоупа, локальный guard команд git/gh и промпт передачи на ревью. Версия `0.2.0-experimental` записана в `protocol/version.json`.

## Состав

- `.cursor/agents/verifier.md` — субагент предварительной сверки
- `.cursor/skills/task-card`, `task-start`, `review-handoff`
- `.cursor/hooks.json` и `scripts/hooks/` — guard и его тесты
- `scripts/verify/` — сбор пакета verifier и тесты сборщика
- `protocol/` — роли, цикл, handoff, вердикт по SHA

Общие правила репозиториев: [конституция github-playbook](https://github.com/Lex226/github-playbook/blob/main/standards/00-constitution.md).

## Как подключить

Подключение ручное: скопировать состав выше в целевой репозиторий с тега `v0.2.0-experimental`. Тег и значение `protocol_version` в `protocol/version.json` совпадают. Движок не подставляет имя целевого проекта. В промпте handoff `<owner>/<repo>` заполняется при выпуске.

## Как выпускается релиз

Релизный pull request переименовывает раздел `## [Unreleased]` в `## [<версия>]` и записывает эту версию в `protocol/version.json`. После merge в `main` workflow `release` создаёт тег `v<версия>` и GitHub Release на merge commit. Если в версии есть `-`, Release публикуется как pre-release. Ручной тег и перенос тега не используются.

## Ограничения

- Guard проверяет командную строку в IDE. Это не изоляция: алиасы git, тело файла у `powershell -File` и вложенные подстановки вроде `$(git …)` он не разбирает как отдельные команды.
- Ответ `ask` может не показать запрос. Причина не выяснена.
- Поведение `deny` и `failClosed` в этом импорте не проверено. В `.cursor/hooks.json` стоит `failClosed: true`, как в источнике.
- Строки причин в `scripts/hooks/guard-git.ps1` называют ADR-0003. Это имя правила в репозитории-источнике. В этом репозитории то же правило записано в `protocol/roles.md`.
- Разбиение цепочек команд учитывает простые кавычки приблизительно. Упоминание git или gh в середине команды даёт `ask`, в том числе для безобидных вызовов вроде `Get-Command git`.
- `scripts/hooks/guard-git.ps1` и матрица его кейсов меняются только после реального инцидента или явного решения владельца.
- Guard не заменяет защиту ветки на GitHub.
- Кейс `github-origin-gh-big-stderr` в `scripts/verify/tests/test-verifier-pack.ps1` стабильно падает по timeout на Windows PowerShell 5.1 (12/1, отчёт Cursor 09.11.2026). Причина не выяснена.
- Доступность субагента verifier (`.cursor/agents/verifier.md`) в инструменте запуска субагентов Cursor зависит от сеанса: 09.11.2026 в сеансе задачи C01 типа `verifier` не было в списке; в сеансе C02 тип `verifier` есть в списке, субагент запустился и вернул ответ. Перед шагом 5 цикла проверять реальным запуском.
- Документация Cursor описывает явный вызов проектного субагента синтаксисом `/имя` в запросе агента: [Subagents](https://cursor.com/docs/subagents).

## Лицензия

MIT, см. LICENSE.
