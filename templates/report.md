# Отчёт исполнителя

Поля ниже совпадают со схемой `schemas/report.schema.json`. Это форма отчёта, не вердикт.

```json
{
  "task_id": "",
  "repository": "",
  "base_sha": "",
  "head_sha": "",
  "protocol_version": "",
  "commands": [
    {
      "command": "",
      "exit_code": 0
    }
  ],
  "evidence": [
    {
      "id": "",
      "status": "instrumented",
      "result": "pass",
      "detail": ""
    },
    {
      "id": "",
      "status": "human_confirmed",
      "result": "pass",
      "detail": ""
    },
    {
      "id": "",
      "status": "not_checked",
      "detail": ""
    }
  ],
  "changed_files": [],
  "limitations": [],
  "unchecked": []
}
```

`exit_code` — код фактически выполненной команды. Статус `not_checked` не заполняется как `pass`.
