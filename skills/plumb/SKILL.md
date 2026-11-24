---
name: plumb
description: >
  Token-lean coding with adaptive depth: lean on small tasks, deeper (git
  history, other modules, full report) only when the task needs it. Use on any
  coding task, and when the user says "plumb", "save tokens", "be lean", or
  asks "why did this break", "since when", or for a full report.
argument-hint: "[auto|quick|normal|deep|off|stats]"
license: MIT
---

# Plumb

Minimise **total tokens until the user has a correct result**, not tokens this
turn. A wrong cheap answer costs a second round. Active until "plumb off".
No status line, banner or mode badge. `stats`: run
`python3 <this skill's dir>/scripts/stats.py` and show its output.

## Depth (pick per task, do not ask)

- **quick**: named target, small clear change. Touch the target and its
  neighbours; reply in 1 to 3 lines.
- **normal**: bug with a known symptom, small feature. Every caller of what you
  change, related tests, one focused test run.
- **deep**: regression ("used to work", "since when"), unknown cause, money,
  auth, permissions, migrations, data deletion, a fix that failed, or an ask to
  investigate or report. Read `references/deep.md` first.

Go up one level on evidence: a failed fix, an unseen caller, or wanting to
write "probably". Say why in one line. Ask first only for large optional work
(many subagents, whole-repo sweeps). A pinned depth that cannot do the task
correctly says what it needs instead of guessing.

## Spend less

- Search first, then read only a line range. Whole file only if short.
- Never re-read a file you just edited.
- Bound every command: `-q`, `| tail -30`, `--stat`, `--oneline`, one test
  before the suite. If you need a count or yes/no, print only that.
- Batch independent calls in one step.
- Wide sweeps go to a search subagent that returns only a conclusion.
- Check project notes and memory before rediscovering.
- No narration, no restating the request, no pasted diff.

## The change

- Least new code: reuse what the codebase has, then the platform, then an
  installed dependency. No unrequested options or abstractions.
- Complete, not partial: update callers, tests and fixtures the change breaks.
  Fix bugs at the root, once.
- **Follow the feature.** State in one sentence what changed for the user,
  search for the same rule, field, status and user-facing text elsewhere
  (other screens, reports, clients, a duplicated constant), and update every
  copy that is now wrong. Too many or risky: finish the core, list the rest,
  ask.
- New logic with a branch, money or security gets one small test.
- Never cut validation, data-loss handling, security, accessibility, the
  project's own checks, or anything asked for.

## Reply

Default: what changed with `file:line`, then what you did not verify, other
places you updated or left (and why), and any risk. When asked for a report or
explanation, give all of it: read `references/report.md`. Separate what you ran
from what you inferred.
