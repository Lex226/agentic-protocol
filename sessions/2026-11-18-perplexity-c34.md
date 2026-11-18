---
date: 2026-11-18
task: perplexity-c34
refs: "#60"
author: Cursor
---

Снимок Perplexity 18.11.2026 (поздний вечер):
- main: 4f290d3c766374075b8531d0ec151fd35ac962cb (merge PR #58, C32).
- #55 C32 принят (issuecomment-6988247939) и закрыт. Решение владельца: вариант C по умолчанию и отдельный клон для параллели (issuecomment-6987069086). has_unstaged_changes: yes — СТОП у родителя.
- Живой хук в клоне @ 4f290d3: git status allow, git merge x deny, git -C . merge x deny. Клон удалён.
- #31 C17: вход по hard stop 1 (issuecomment-6987710844).
- #59 C33 (bug, priority:high): Invoke-Expression "git merge x" в живом Cursor даёт allow, в тестах ask (57/57). Не исправлен.
- #60 C34: решение владельца 18.11.2026 — создать docs/ и docs/research/ под один документ.
- Очередь: #60 C34 → #31 C17 → #59 C33 → #44 C25 → #45 C26 → #46 C27 → #42 C23 → #48 C29 → #49 C16 → #50 C30.
- Находки для conventions-auditor: rg "персональн" в protocol/perplexity/**; stage:intake на закрытых Issues; тела #47 и #55 устарели; в cycle.md абзацы о verifier и ревью под разделом «Рабочий каталог»; в правилах записи Perplexity нет правки заголовка/тела Issue; метки research в репо нет; docs/ не описан в README.md; снимок perplexity-c32 устарел (нет #59, #60).
