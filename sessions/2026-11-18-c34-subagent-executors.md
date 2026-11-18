---
date: 2026-11-18
task: c34-subagent-executors
refs: "#60"
author: Cursor
---

# C34: субагенты-исполнители в отдельных клонах

## Задача / ветка / commit

- Issue #60, `Refs #60`. Тип `docs-only`. Карточка выведена, исключение docs-only соблюдено, остановки на «да» не было. После первого СТОП владелец 18.11.2026 разрешил создать `docs/` и `docs/research/` под один документ.
- Ветка `c34-subagent-executors-research` от `origin/main` `4f290d3c766374075b8531d0ec151fd35ac962cb` (merge PR #58, C32). Перед созданием ветки дерево было чистым, текущая ветка checkout после переключения — `main`. `git fetch origin`: факт совпал с ожидаемым SHA. `git ls-remote --heads origin c34-subagent-executors-research` был пуст. `git switch -c` поставил upstream на `origin/main`; затем `git branch --unset-upstream`.
- `AGENTS.md` в репозитории нет.
- Этот текст входит в commit ветки. Полный SHA — в handoff.

## Сделано

Один новый файл `docs/research/2026-11-18-c34-subagent-executors.md`. Других файлов в `docs/` нет. Вопросы 1–5, таблица вариантов и рекомендация. Выбор оставлен владельцу. Правки `protocol/`, `.cursor/`, `scripts/`, `README.md`, `CHANGELOG.md` не делались.

Рекомендация документа: не вводить пишущих субагентов и CLI/headless в клонах; дробление, если оно понадобится после закрытия #59, — отдельные Issue (клон, окно, PR, очередь ревью). До закрытия #59 параллельные пишущие окна не открывать.

Снимки: этот файл и `sessions/2026-11-18-perplexity-c34.md`.

## Решения

Решение владельца 18.11.2026: продолжить после СТОП и создать каталоги `docs/` и `docs/research/` ради одного документа. README, индекс и `.gitkeep` не добавлять.

Пишущие субагенты не запускались. Обход guard из #59 не повторялся. Облачные агенты и платные сервисы не подключались.

## Проверки

Среда: Windows PowerShell 5.1.

| Проверка | Результат |
|---|---|
| `git diff --cached --check` | exit 0, вывод пустой |
| `git diff --cached --stat` | 3 files changed, 214 insertions(+): документ и два снимка |
| закрывающие ключи и секреты в индексе | закрывающих ключей Issue нет. Имя переменной `CURSOR_API_KEY` есть в документе как цитата страницы CLI, значения нет. Секретов нет |
| внешние ссылки документа с датой чтения | шесть URL, у каждой «чтение 18.11.2026» на строке или в заголовке списка источников |
| живой хук и пишущие субагенты | не запускались: #59 открыт, бриф запрещает эксперимент |

### verifier (субагент)

Запущено. Сбор `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify/collect-verifier-pack.ps1 -Issue 60` после staging, до этого абзаца: exit 0. Fingerprint пакета: `branch` `c34-subagent-executors-research`, `origin_main_sha` `4f290d3c766374075b8531d0ec151fd35ac962cb`, `name_status_count` 3, `has_unstaged_changes` no, `diff_mode` full, `sessions_count` 2, `sessions_paths` `sessions/2026-11-18-c34-subagent-executors.md, sessions/2026-11-18-perplexity-c34.md`. `git diff --cached --stat` до этого абзаца: 3 files changed, 214 insertions(+).

Субагент вернул отчёт. Input fingerprint совпал со всеми семью полями. Подтвердил вопросы 1–5 с датами чтения, таблицу и рекомендацию, шесть кандидатов Issue без правок правил, оба снимка и то, что в diff только эти три файла. Claimed but missing: нет. Out of scope: нет. Git субагент не запускал. дописано после прогона.

## Блокеры

Нет блокера публикации. Хвосты: кандидаты Issue в документе (roles, cycle, task-start, guard, verifier, README про `docs/`); #59 не исправлен; тело #55 и снимок perplexity-c32 устарели относительно очереди.

## Следующий шаг

Ревью Perplexity по handoff и merge проверенного SHA, если блокирующих замечаний нет. Issue #60 этим merge не закрывается. Очередь после него: #31 C17, затем #59 C33.
