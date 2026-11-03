# Контракт передачи

Между исполнителем и ревьюером передаются три документа. Их форма задана схемами в `schemas/` и шаблонами в `templates/`.

## Задание

Обязательные поля: `task_id`, `scope`, `allowed_paths`, `forbidden_paths`, `acceptance_criteria`.

Исполнитель не расширяет область работы молча. Путь вне `allowed_paths` или внутри `forbidden_paths` не меняется без нового задания.

## Отчёт

Обязательные поля: `task_id`, `repository`, `base_sha`, `head_sha`, `protocol_version`, `commands`, `evidence`, `changed_files`, `limitations`, `unchecked`.

Каждая команда содержит строку запуска и целочисленный `exit_code` того запуска, который реально был. Пропущенный, предполагаемый или скопированный из старой переписки результат в отчёт не входит.

Каждый элемент `evidence` имеет статус:

- `instrumented` — проверка выполнена командой или инструментом;
- `human_confirmed` — вывод подтвердил человек;
- `not_checked` — проверка не выполнялась.

У `not_checked` не может быть `result: pass`. Отсутствие проверки не считается успешным прохождением. Непроверенный пункт остаётся в `unchecked`, даже если рядом есть другие успешные проверки.

В отчёте нет полей вердикта. Исполнитель не записывает READY, FIX или BLOCK от своего имени.

## Вердикт

Обязательные поля: `task_id`, `reviewed_head_sha`, `decision`, `issuer`, `notes`, `merge_conditions`.

`decision` — одно из READY, FIX, BLOCK. `issuer` всегда `reviewer`.

READY разрешает merge только того коммита, чей полный SHA равен `reviewed_head_sha`, и только если выполнены `merge_conditions`. Новый коммит делает прежний READY недействительным.
