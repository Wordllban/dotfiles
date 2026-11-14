---
name: signoff
description: List what is waiting on my decision, review, or sign-off - in this session, or across the repo when the session holds nothing.
argument-hint: "(optional) wider scope, e.g. 'my PRs' or 'the PROJ board'"
disable-model-invocation: true
---

Build the user's **sign-off queue**: every item that stays parked until they
act. They answer between other sessions, so one short reply must be able to
clear the whole queue.

An item is in the queue only when the user is the blocker. Three kinds:

- **Decide** - a question you asked or options you offered, still unanswered.
  Includes each assumption you made on their behalf and then built on.
- **Review** - work you reported done that they have not acknowledged: a diff,
  a plan, a draft, a finding.
- **Approve** - an action held for their go-ahead: commit, push, PR, merge,
  deploy, a message to send, a declined permission prompt.

## 1. Sweep

Scope is this session. The sweep is done when every question you asked, every
completion you reported, and every action you held is either in the queue or
answered by a later user message.

When the session holds nothing (fresh, or compacted past recall) or the
arguments name a wider scope, sweep the environment in one parallel batch:

- `git status --short --branch` and `git log @{u}..HEAD --oneline`: finished
  work left uncommitted or unpushed is an **Approve**.
- `gh pr status`: a review request is a **Review**; their own PR approved and
  green is an **Approve**; one with changes requested is a **Decide**.
- Whatever the arguments name (a ticket board, a plan file, another repo),
  through the CLI that reaches it.

After a compaction, say which part of the session you can no longer see.

The sweep is read-only: every item stays parked until the user replies.

## 2. Report

Number the items, most downstream work unblocked first, so the user can reply
`1 yes, 2 b, 3 later`:

```
N. **Kind** - the ask, phrased so yes/no or an option letter answers it
   Context: the one fact they need - `path:line`, PR number, options a/b
   Recommend: your pick, with the reason in a clause
   Unblocks: what proceeds once they answer
```

Close with one line, `Not on you:`, naming what is moving by itself or waits on
something else (a running job, CI, another person). An empty queue is that
line under `Nothing is waiting on you.`
