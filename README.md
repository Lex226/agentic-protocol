# agentic-protocol

Shared protocol for agent task, report, and review handoff.

## Назначение

Каноническая копия движка Cursor для согласованной задачи: карточка, предварительная сверка скоупа, локальный guard команд git/gh и промпт передачи на ревью. Версия `0.2.0-experimental` записана в `protocol/version.json`.

## Состав

- `.cursor/agents/verifier.md` — субагент предварительной сверки
- `.cursor/skills/task-card`, `task-start`, `review-handoff`
- `.cursor/hooks.json` и `scripts/hooks/` — guard и его тесты
- `scripts/verify/` — сбор пакета verifier и тесты сборщика
- `scripts/labels/` — аддитивный накат меток
- `protocol/` — роли, цикл, платформа, handoff, вердикт по SHA
- `adr/` — архитектурные решения: шаблон `ADR-0001-template.md` и `ADR-0002-universal-protocol.md` (статус Proposed)

`.github/workflows/` относятся к репозиторию `agentic-protocol` и в состав для копирования не входят.

Общие правила репозиториев: [конституция github-playbook](https://github.com/Lex226/github-playbook/blob/main/standards/00-constitution.md).

## Как подключить

Подключение ручное: скопировать состав выше в целевой репозиторий с тега `v0.2.0-experimental`. Тег и значение `protocol_version` в `protocol/version.json` совпадают. Движок не подставляет имя целевого проекта. В промпте handoff `<owner>/<repo>` заполняется при выпуске. `.github/workflows/` потребителю не копируются.

## Как выпускается релиз

Релизный pull request переименовывает раздел `## [Unreleased]` в `## [<версия>]` и записывает эту версию в `protocol/version.json`. После merge в `main` workflow `release` создаёт тег `v<версия>` и GitHub Release на merge commit. Если в версии есть `-`, Release публикуется как pre-release. Ручной тег и перенос тега не используются.

## Работа без серверной защиты

Правило процесса — в `protocol/platform.md`. Базовая линия — private на GitHub Free: протокол не требует rulesets, protected branches и required status checks. Чтение docs.github.com: 09.11.2026.

| Видимость × план | GitHub | Протокол |
|---|---|---|
| public × Free | Rulesets и protected branches доступны. Required status checks — настройка branch protection rule; вывод: доступны там же, где protected branches. Actions на стандартных раннерах бесплатны. | Те же шаги, что на базовой линии. Серверная защита рекомендуется и не обязательна. |
| private × Free | Rulesets и protected branches для private на Free в цитатах ниже не указаны. Required status checks — тот же вывод. Actions в private расходуют включённый лимит плана. | Базовая линия. Шаг цикла не требует этих механизмов. |
| public × Pro, Team, Enterprise Cloud | Rulesets доступны. Protected branches доступны; для них также назван Enterprise Server. Required status checks — тот же вывод. | Те же шаги. Серверная защита рекомендуется и не обязательна. |
| private × Pro, Team, Enterprise Cloud | Rulesets доступны. Protected branches доступны, включая Enterprise Server. Required status checks — тот же вывод. | Те же шаги. У личного аккаунта-владельца процесс остаётся основной защитой и на платном плане. |

Rulesets, блок «Who can use this feature?» на [About rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets):

> Rulesets are available in public repositories with GitHub Free and GitHub Free for organizations, and in public and private repositories with GitHub Pro, GitHub Team, and GitHub Enterprise Cloud.

Фраза на той же странице про customers on GitHub Team and GitHub Enterprise относится к rulesets уровня организации, не к этой доступности.

Protected branches, блок «Who can use this feature?» на [About protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches):

> Protected branches are available in public repositories with GitHub Free and GitHub Free for organizations. Protected branches are also available in public and private repositories with GitHub Pro, GitHub Team, GitHub Enterprise Cloud, and GitHub Enterprise Server.

Required status checks: настройка branch protection rule, раздел [Require status checks before merging](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches#require-status-checks-before-merging). Вывод: доступны там же, где protected branches.

Actions: [GitHub's plans](https://docs.github.com/en/get-started/learning-about-github/githubs-plans) — на стандартных раннерах в public бесплатны; в private расходуется включённый лимит плана.

## Ограничения

- Guard проверяет командную строку в IDE. Это не изоляция: алиасы git, тело файла у `powershell -File` и вложенные подстановки вроде `$(git …)` он не разбирает как отдельные команды.
- Ответ `ask` может не показать запрос. Причина не выяснена.
- Поведение `deny` и `failClosed` в этом импорте не проверено. В `.cursor/hooks.json` стоит `failClosed: true`, как в источнике.
- Строки причин в `scripts/hooks/guard-git.ps1` называют ADR-0003. Это имя правила в репозитории-источнике. В этом репозитории то же правило записано в `protocol/roles.md`.
- Разбиение цепочек команд учитывает простые кавычки приблизительно. Упоминание git или gh в середине команды даёт `ask`, в том числе для безобидных вызовов вроде `Get-Command git`.
- `scripts/hooks/guard-git.ps1` и матрица его кейсов меняются только после реального инцидента или явного решения владельца.
- Guard не заменяет защиту ветки на GitHub.
- Доступность субагента verifier (`.cursor/agents/verifier.md`) в инструменте запуска субагентов Cursor зависит от сеанса: 09.11.2026 в сеансе задачи C01 типа `verifier` не было в списке; в сеансе C02 тип `verifier` есть в списке, субагент запустился и вернул ответ. Перед шагом 5 цикла проверять реальным запуском.
- Документация Cursor описывает явный вызов проектного субагента синтаксисом `/имя` в запросе агента: [Subagents](https://cursor.com/docs/subagents).

## Лицензия

MIT, см. LICENSE.
