---
name: recaper
description: Recap this session - the goal, where the work stands, and what is left - so the user can resume after switching away to another terminal or a meeting.
argument-hint: "(optional) area to focus on, e.g. 'the migration' or 'just blockers'"
disable-model-invocation: true
---

The user runs several coding agent sessions at once and has been away from this
one. Rebuild their context in a single, scannable message.

Write for someone who wrote the original request but no longer remembers the
details. Recap this session only. Never invent progress: if the conversation was
compacted or the session is fresh, say what is unknown instead of guessing, and
fall back to repository evidence.

## Gather first

Before writing, collect evidence in one parallel batch:

- `git status --short --branch`, `git diff --stat`, `git diff --cached --stat`
- `git log --oneline -5` and `git stash list`
- Pending todos, background shells still running, and spawned agents whose
  results have not arrived
- The last failing command or test output, if any

Read files only when the recap would otherwise be wrong. Do not start new work,
do not fix anything, and do not commit.

## Output format

Exactly these three sections, in this order.

### 1. Goal

One or two sentences on what the user asked for and why. Include explicit
constraints or decisions already made (approach chosen, libraries ruled out,
scope deliberately cut).

### 2. Where we are

What is actually done, grounded in evidence. Reference files as
`path/to/file.ts:42` rather than describing them. Name the branch and whether
changes are uncommitted, staged, or pushed. State the verification status
plainly: tests passing, untested, or failing with the error.

### 3. What is left

Ordered next steps, most immediate first. Mark each blocker with **BLOCKED:**
and name what it waits on: a user decision, a review, a running job, missing
credentials. Close with the single next action to take.

## Style

- Bullets, not paragraphs. Aim for 15 lines or fewer, hard cap 25.
- Concrete over narrative: no retelling of the tool calls you made.
- If arguments were passed, treat them as the focus and keep the rest to one
  line per section.
