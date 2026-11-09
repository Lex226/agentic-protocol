---
name: review-handoff
description: >-
  Generates the Perplexity review handoff mini-prompt after the last push of an
  agreed task. Use as the final step of every task and again after every
  fix-push; the previous prompt becomes invalid when HEAD changes.
---

# Review handoff

## When

- Last step of an agreed task, after commit, push, and PR create/update.
- Again after every fix-push on the same PR (new full SHA).

Without this prompt the task is **not** handed off for Perplexity review (protocol/handoff.md).

## Rules

1. Use the **full** commit SHA after the **last** successful push (`git rev-parse HEAD` on the published tip).
2. After a fix-push, emit a **new** prompt; the old one is invalid.
3. In **Запущено** list only commands that were actually run and their real results. Distinguish **`verifier (субагент)`** (pack analyzed by the readonly verifier subagent) from **сверка родителем** (parent-only check without a verifier subagent run).
4. In **Не запущено / вручную** list gaps honestly. Absence of CI is not a green CI result.
5. Do not merge, enable auto-merge, or ask Cursor to merge.
6. Prefer `Refs #<N>` (not `Closes`) unless the owner explicitly agreed to close the Issue on merge.
7. Fill placeholders from the current PR and repository. `<owner>/<repo>` is the repository being reviewed. Never hardcode a past Issue number, owner, or repository name into the skill itself.

## Output

Emit a single fenced `text` block the parent can paste:

```text
Perplexity, выполни ревью PR #<N> в <owner>/<repo>
и смёржи, если блокирующих замечаний нет (protocol/roles.md).

Ветка: <branch> → main
HEAD: <full SHA after last push> ← мёржить только этот SHA
Issue: Refs #<N> (не закрывать автоматически)
Запущено: <commands and results>
Не запущено / вручную: <list or «нет»>
Обрати внимание: <1–3 items or «—»>
```
