# Вердикт ревьюера

Поля ниже совпадают со схемой `schemas/verdict.schema.json`. Документ заполняет ревьюер.

```json
{
  "task_id": "",
  "reviewed_head_sha": "",
  "decision": "FIX",
  "issuer": "reviewer",
  "notes": [],
  "merge_conditions": []
}
```

`decision` — READY, FIX или BLOCK. `issuer` равен `reviewer`. READY относится только к полному `reviewed_head_sha`.
