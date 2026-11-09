# Платформа

## Работа без серверной защиты

Базовая линия — приватный репозиторий на GitHub Free.

Протокол не требует rulesets, protected branches и required status checks. Шаг цикла от них не зависит.

Их место занимают:

- guard в IDE проверяет командную строку git и gh;
- merge в `main` делает только ревьюер и только для SHA из актуального handoff (`expectedHeadSha`);
- ревьюер сам сверяет check runs: отсутствие CI не считается зелёным результатом;
- в процессе задачи запрещены force-push и прямой push в `main`.

Если защита доступна — public-репозиторий или платный план — её настройка рекомендуется. Она не является условием шага.

По умолчанию ограничения branch protection rule не применяются к администраторам репозитория. Добавить участника в список обхода можно только у репозитория организации ([About protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches), чтение 09.11.2026). У личного аккаунта-владельца процесс остаётся основной защитой и на платном плане.

Матрица плана — в `README.md`.
