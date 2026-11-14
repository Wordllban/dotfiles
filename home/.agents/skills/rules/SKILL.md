---
name: rules
description: Re-read the instruction files that govern this session and correct any drift from them.
argument-hint: "(optional) a rule or file to focus on"
disable-model-invocation: true
---

Long sessions and compactions cause **drift**: the rules still apply, but the
work has stopped following them. Reload the rules from disk, then correct the
drift.

## 1. Reload

Read from disk, in one parallel batch, every instruction file that governs
this session. The copy in context may be summarized or stale.

- User level: `~/.claude/CLAUDE.md`, `~/AGENTS.md`, `~/.claude/rules/`, and
  each `@import` they name.
- Project root: `AGENTS.md`, `CLAUDE.md`, `.claude/rules/`, `.cursor/rules/`.
- Nested: `AGENTS.md` and `CLAUDE.md` in every directory this session
  touched, and in each parent up to the root.

Done when every file that exists at those paths has been read in this turn.

## 2. Correct

Check the session's work against every rule: files changed, commits made,
messages drafted, the approach in progress. With arguments, check that rule or
file first and in the most depth.

Fix each drift that is local and reversible. Queue the rest (a pushed commit,
a sent message) for the user.

Report one line per drift - the rule, where it broke, fixed or queued - or
`No drift.` Then resume the task in hand.
