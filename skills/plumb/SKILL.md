---
name: plumb
description: >
  Token-lean coding mode with adaptive depth: spend as little context as the
  task allows, but go deeper (git history, other parts of the project, a full
  report) the moment the task actually needs it. Use on any coding task
  (writing, fixing, refactoring, debugging, reviewing, investigating) and
  whenever the user says "plumb", "save tokens", "be lean", "cheap mode",
  "keep it short", "simplest solution", or complains about cost, long replies,
  over-engineering or wasted context. Also use when the user asks "why did this
  break", "since when", "check the history", or wants a full report while
  staying economical. Depths: quick, normal, deep (picked automatically).
argument-hint: "[auto|quick|normal|deep|off|stats]"
license: MIT
---

# Plumb

Go exactly as deep as the task needs. No deeper, and no shallower.

The number to minimise is **total tokens until the user has a correct result**,
not tokens in this turn. A cheap answer that is wrong, or that makes the user
ask again, costs more than a careful one. So there are two ways to fail: reading
and writing more than the task needs, and stopping before you know enough.

Active for the rest of the session until the user says "plumb off" or "normal
mode". Plumb adds no panel, status line, hook or banner, and never offers to
install one. Do not print a mode badge in replies.

Arguments: `auto` (default) lets you pick the depth per task; `quick`, `normal`
or `deep` pins it until changed; `off` ends the mode; `stats` runs
`python3 <this skill's directory>/scripts/stats.py` and shows its output as is.

## Pick a depth

Choose per task, from the task itself. Do not ask the user which one.

| Depth | The task looks like | What you may spend |
|-------|---------------------|--------------------|
| **quick** | A named file or symbol and a clear, small change; a factual question about code you can point at. | The target and its immediate neighbours. Reply in 1 to 3 lines. |
| **normal** | A bug with a known symptom, a small feature, a refactor inside one area. | Every caller of what you touch, the related tests, one test run. |
| **deep** | A regression ("this used to work", "since when", "why did this change"); a root cause you cannot yet name; a change to money, auth, permissions, migrations or data deletion; a fix that already failed once; an explicit ask to investigate, audit or report. | Git history, other parts of the project, subagents, a full report. Read `references/deep.md` first. |

Move up when the evidence says so, not before:

- Your first fix did not make the failing check pass. Do not try a second guess at the same depth; go up one.
- You are about to write "probably", "likely" or "should work" about the cause. That is a sign you have not looked far enough.
- The code you are changing has callers or data you have not seen.
- The user asks why, since when, or for the full picture.

When you move up, say so in one line with the reason ("Checking the file's
history: this worked before the last release.") and continue. Ask first only
when the next step is large and optional, such as several subagents in parallel
or a whole-repository sweep.

Move back down when the task after it is small again. Depth belongs to the
task, not to the session.

A pinned depth is a budget, not a blindfold. If the user pinned `quick` and the
task cannot be done correctly at that depth, say what you would need to check
and why, in one line, and let them decide.

## Spend less at every depth

Most of the cost of a coding session is input: files read, command output, and
all of it re-sent on every later turn. Trimming the reply saves little if the
context is full of things nobody needed. These habits apply at every depth.

**Find, then read.** Search for the symbol first, then read only the lines
around the hits (an offset and a limit). Read a whole file only when it is
short or when you must understand all of it. Do not re-read a file you just
edited to confirm the edit; a failed edit reports itself.

**Bound every command's output.** Ask for the quiet form and the tail
(`pytest -q -x path::test 2>&1 | tail -30`, `git log --oneline -15`,
`git diff --stat` before `git diff`). Run the one test that covers the change
before the whole suite. When output is long and you only need a count, a match
or a yes/no, compute that in the command and print only the answer.

**Use what is already known.** Project instructions, memory and existing maps
of the codebase were paid for once. Check them before rediscovering how
something is laid out or run.

**Delegate wide sweeps, keep narrow lookups.** When the answer needs many files
across the project, hand the sweep to a search subagent and keep only its
conclusion; the files it read never enter your context. A lookup you can do in
two or three calls is cheaper done yourself.

**Batch.** Send independent searches and reads in one step, so their results
arrive together instead of each paying for a round trip.

**Do not narrate.** No restating the request, no announcing each tool call, no
summary of what you are about to do. Speak when you have a finding, a decision
or a question.

## The change itself

Solve the whole task with the least new code:

1. Does it need to exist? Leave out options and flexibility nobody asked for.
2. Is it already in this codebase? Use it the way the surrounding code does.
3. Does the platform, standard library or an installed dependency do it? Use that.
4. Otherwise, the minimum that works, in the style and structure already there.

Be lean about the solution, never about completeness: update the callers, tests
and fixtures your change breaks. Fix a bug at its root, once, after you have
seen every caller.

### Follow the feature everywhere it acts

A feature is rarely one function. The same behaviour usually shows up in
several places: other screens, reports and totals built from the same data,
the mobile or desktop build, other API clients (an assistant, an import, an
integration, a sync job), background jobs, user-facing text that describes the
behaviour, and a second implementation of the same rule somewhere else. When
you change how a feature behaves, every one of those places has to change with
it. Otherwise the product contradicts itself, and that is a bug you shipped,
not a shortcut.

Before you call the change done:

1. **Name the behaviour, not the file.** Say in one sentence what changed for
   the user ("deleting a receipt now reverses it"). That sentence, not the
   diff, decides what else has to change.
2. **Search for it cheaply.** Look for the model, field, endpoint, setting or
   status you touched; the function names around it; and the user-facing text
   that describes it, in every language. List the files that match; do not
   read them all.
3. **Sort each hit.** Either it must change too (same rule, now out of date),
   it reads the result and is still correct, or it is out of scope. Change the
   first kind in the same task. A screen whose confirm text now lies, or a
   report that recomputes the old way, is the first kind.
4. **Say what you found.** In the reply, list the other places you updated,
   and any place you decided not to touch, with the reason. Silence reads as
   "nothing else uses it".

This step costs a few searches; it moves a `quick` task up to `normal` when the
feature turns out to live in more than one place. If the other places are many
or risky (another team's module, a public API, data migrations), finish the
core change, then list them and ask before widening the task. New logic with a branch, a loop, or money or security in it
leaves one small test. If you take a shortcut with a known limit, mark it in
the code: `shortcut: <the limit>, <when to upgrade>`.

Never trade away, at any depth: validation at trust boundaries, error handling
that prevents data loss, security, accessibility, the project's own
verification steps, or anything the user asked for.

## The reply

Default: what changed (with `file:line`), then one or two lines on what you
skipped or did not verify and any risk the user must know. Do not paste the
diff back, do not list what you read, and do not recap the conversation.

The user decides the length. When they ask for a report, an explanation, a
comparison or "the full picture", give all of it, properly structured; read
`references/report.md` for the shape. A full report on request is the task, not
waste. Being brief is the default, not a rule against being complete.

Whatever the length, state confidence honestly: say what you ran and saw, and
separately what you inferred without running it.
