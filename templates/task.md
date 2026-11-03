# Задание

Поля ниже совпадают со схемой `schemas/task.schema.json`.

```json
{
  "task_id": "",
  "scope": "",
  "allowed_paths": [],
  "forbidden_paths": [],
  "acceptance_criteria": []
}
```

`allowed_paths` ограничивает, что исполнитель может менять. `forbidden_paths` перечисляет запрещённые пути. Нормативные правила передачи лежат в `protocol/`, а не в этом шаблоне.
