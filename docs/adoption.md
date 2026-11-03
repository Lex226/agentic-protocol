# Подключение проекта

Протокол подключается конкретным коммитом, а не плавающей веткой.

1. Добавьте сабмодуль `https://github.com/Lex226/agentic-protocol.git` по пути `.agentic/vendor/protocol`.
2. Зафиксируйте полный SHA принятого коммита. SHA из переписки, которого нет в репозитории протокола, не используется.
3. Создайте `.agentic/config.json`:

```json
{
  "protocol_repository": "Lex226/agentic-protocol",
  "vendor_path": ".agentic/vendor/protocol",
  "protocol_version": "0.1.0",
  "protocol_ref": "<40-hex SHA закреплённого коммита>"
}
```

4. Из каталога потребителя выполните:

```bash
node .agentic/vendor/protocol/scripts/generate-adapters.mjs --write --target .
node .agentic/vendor/protocol/scripts/verify-pin.mjs --target .
node .agentic/vendor/protocol/scripts/generate-adapters.mjs --check --target .
```

5. Закоммитьте `.gitmodules`, gitlink сабмодуля, `.agentic/config.json` и четыре адаптера.
6. В CI потребителя оставьте чтение содержимого (`contents: read`), сверку pin и `--check`. Не отключайте эти шаги, чтобы получить зелёный статус.

Генератор останавливается, если `.cursor/rules/agentic.mdc` или другой его выходной файл уже существует без маркера `agentic-protocol: generated`. Чужой `AGENTS.md` и прочие файлы `.cursor/rules/` он не перезаписывает.

Если pin временно указывает на ещё не принятый коммит ветки, pull request потребителя остаётся draft. Перед приёмкой переведите сабмодуль на SHA, который фактически оказался в `main` протокола. Squash-merge создаёт новый SHA. Ветку с временным коммитом не удаляйте, пока на неё смотрит gitlink.
