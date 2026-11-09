---
name: task-start
description: >-
  Runs the standard start-to-handoff cycle for an agreed task from a short
  Perplexity brief. Use when the owner pastes a brief that says
  «По скиллу task-start». The brief carries only task-specific fields;
  everything else comes from this skill.
---

# Task start

## Input

A brief in a fenced `text` block (format below). If a required field is
missing or contradicts AGENTS.md/ADR — STOP and list the gaps; do not guess.

## Steps

0. **Start point.** `git status` must be clean, else STOP. `git fetch origin`,
   then `git switch -c <branch> origin/main`. Do not compare with any SHA from
   the brief. For every `blob` line in the brief, compare with
   `git rev-parse origin/main:<path>`; mismatch → STOP with
   «файл / ожидался / факт / коммит». Record the base: `git rev-parse origin/main`.
1. **Read.** `README.md`, `protocol/` (roles, cycle, handoff, verdict), `AGENTS.md`
   when the repository has one, the Issue, the brief's sources and the latest
   file in `sessions/`. If the brief names a sample
   commit/file, follow its format exactly; if the sample changed something
   outside the brief's scope, report it as a tail, do not copy it.
2. **Task card.** Use skill `task-card`. If brief says `task-card: СТОП` —
   stop and wait for the owner's answer. If `продолжить` — print the card and
   go on (only when protocol/cycle.md section «Исключение docs-only» applies; a consumer AGENTS.md may only tighten that rule;
   otherwise treat as СТОП and say so).
3. **Edit** only the items under «Скоуп». An item that needs a new requirement
   is not edited: mark «требует решения владельца» and report it.
4. **Do not touch** the brief's «Не трогать» list, plus always: new
   requirements, requirement IDs, domain object names, other PRs/branches. Out-of-scope
   findings go to tails, not edits.
5. **Snapshot** in the same branch: `sessions/<YYYY-MM-DD>-<task>-<topic>.md`.
   Frontmatter exactly: `date`, `task`, `refs`, `author: Cursor`.
   Sections: as defined in `protocol/cycle.md`, «Снимок сессии».
   Do not duplicate the section list in this skill.
   Write the snapshot as of the commit it belongs to: no future-tense steps
   about packs, commit or push. «Следующий шаг» = Perplexity review by handoff
   (and what follows after merge).
6. **Checks** (report only what actually ran, with results). Stage the scope
   files and the snapshot, then `git diff --cached --check` and
   `git diff --cached --stat` (expected files from the brief + snapshot).
   Run brief-specific checks. Search the staged diff for secrets and
   `Closes|Fixes|Resolves`. Collect
   `scripts/verify/collect-verifier-pack.ps1 -Issue <N>` and pass it to the
   readonly verifier subagent. In the report and the handoff, label that run
   `verifier (субагент)`. A parent-only check without that subagent is
   `сверка родителем`.
7. **Publish** (protocol/roles.md). The commit includes the snapshot. Commit with the
   brief's message and `Refs #<N>` in the body. Normal push, no force:
   `git push -u origin HEAD` (do not push `main`). PR to main with Refs, no
   Closes. Do not merge, do not enable auto-merge. Search the PR body for
   secrets and `Closes|Fixes|Resolves` before handoff. Handoff uses the full
   SHA of this push.
8. **Report:** база (SHA) / файлы / запущено / не запущено /
   `verifier (субагент)` или `сверка родителем` / хвосты / решения владельца /
   next step.
9. **Last block:** skill `review-handoff` with the full SHA after the last push.

## On owner reply «Ответ владельца: да, с правками…»

Apply the listed fixes, then continue from step 3 without stopping. A line
«Расширение скоупа (решение владельца)» adds to «Скоуп»; nothing else does.

## Brief format

```text
Задача: Issue #<N> «<заголовок>». Refs #<N>[, #<M>]. Тип: <docs-only|code|hook>.
По скиллу task-start.
Ветка: <type/name>
Основание: <Issue/комментарий ID, дата>
Blob: <path> = <sha> [; …] | нет
Образец: <commit/file> | нет
task-card: <СТОП|продолжить>
Скоуп:
1. <файл, место: было → стало / правило>
Не трогать: <список> | стандарт
Проверки сверх стандарта: <…> | нет
Коммит: «<сообщение>»
```

Never hardcode a past Issue number, SHA or blob into this skill.
