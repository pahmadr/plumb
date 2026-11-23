# plumb

A Claude Code skill that makes the agent go **exactly as deep as the task
needs**: lean on small tasks, thorough on hard ones.

Most "save tokens" prompts make the agent cheaper per turn by making it look
less. That works until a task needs a look at the git history, another module,
or a full write-up. Then the cheap answer is wrong, the user asks again, and the
session ends up costing more. plumb minimises a different number:

> **total tokens until the user has a correct result.**

It has two halves:

1. **Spend less at every step.** Most of a coding session's cost is input:
   files read, command output, and all of it re-sent on every later turn. plumb
   cuts that first: search before reading, read line ranges, bound every
   command's output, never re-read a file just edited, delegate wide sweeps to
   a subagent that returns only its conclusion, and no narration.
2. **Go deeper only on evidence.** Three depths, picked per task: `quick`,
   `normal` and `deep`. The agent moves up when the evidence calls for it: a
   failed fix, a regression ("it worked last week"), money, auth or data
   deletion, or a cause it can only describe with "probably". When it moves up,
   it says so in one line and why.

It also checks, before calling a change done, that the change reaches every
place the feature acts: other screens, reports, clients, text that describes
the behaviour, a second copy of the same rule.

No status line, no panel, no hooks, no banner. One skill file, about 2,000
tokens, loaded only when it triggers.

## Install

As a plugin:

```text
/plugin marketplace add pahmadr/plumb
/plugin install plumb@plumb
```

Or copy the skill folder:

```bash
git clone https://github.com/pahmadr/plumb
cp -R plumb/skills/plumb ~/.claude/skills/plumb
```

It triggers on its own for coding tasks and when you say things like "be
lean", "save tokens" or "why did this break". You can also call it directly.

## Use

| Command | What it does |
|---------|--------------|
| `/plumb` or `/plumb auto` | Pick the depth per task (default). |
| `/plumb quick`, `/plumb normal`, `/plumb deep` | Pin a depth until changed. A pinned `quick` that cannot do the task correctly says what it would need to check, instead of guessing. |
| `/plumb stats` | This session's token usage, and which tools put the most text into the context. Runs a script; costs no model tokens beyond its output. |
| `/plumb off` | Back to normal behaviour. |

### The three depths

| Depth | When | What it may spend |
|-------|------|-------------------|
| quick | A named file or symbol and a small, clear change; a question about code it can point at. | The target and its neighbours. A 1 to 3 line reply. |
| normal | A bug with a known symptom, a small feature, a refactor in one area. | Every caller of what it touches, the related tests, one test run. |
| deep | A regression, an unknown root cause, money, auth, permissions, migrations or data deletion, a fix that already failed, or an explicit ask to investigate or report. | Git history, other parts of the project, subagents, a full report. |

At `deep`, `references/deep.md` loads with the cheapest command for each
history question (`git log -S`, `git log -L`, `git blame -L`, `git bisect run`)
and where causes tend to hide outside the file in front of you. When the user
asks for a report, `references/report.md` loads with the shape: answer first,
findings with evidence, what to do, what was not checked. Neither file costs
anything until it is needed.

### Replies

By default: what changed, with `file:line`, then one or two lines on what was
not verified and any risk. No pasted diff, no list of files read, no recap.
When you ask for a report or an explanation, you get the whole thing. Being
brief is the default, not a rule against being complete.

## Where the savings come from

| Habit | Why it saves |
|-------|--------------|
| Search, then read a line range | A 2,000-line file read for one function costs ~25k tokens, then rides along in every later turn. |
| Bound command output (`-q`, `tail`, `--stat`, `--oneline`) | A full test run or `git log -p` can be larger than everything else in the session. |
| One focused test before the suite | The failure you care about, without a page of passing tests. |
| No re-read after an edit | The edit tool already reports failure. |
| Subagent for wide sweeps | The files it reads never enter your context; only its conclusion does. |
| Batch independent calls | One round trip instead of several. |
| Reuse project notes and memory | Paid for once; rediscovery pays again. |
| No narration, no pasted diff | Output tokens are the most expensive per token. |
| Reference files load only at depth | `deep` and report guidance cost nothing on quick tasks. |

And where it spends on purpose: reading history for a regression, following a
change to every place the feature acts, and writing a full report when asked.
Those are the cases where skipping the work costs a second round, or a bug in
production.

## Results so far

Measured on a real Django and Next.js codebase, single runs, details in
[benchmarks/RESULTS.md](benchmarks/RESULTS.md):

| Task | Compared with | Tokens | Outcome |
|------|---------------|-------:|---------|
| Product question | no skill | +5% | Same advice, better backed by the code. |
| Multi-module data-integrity investigation | ponytail | +12% | Found the same serious bug, plus a second real bug the other run missed. Both were then fixed. |

Honestly: these runs do not show plumb saving tokens. They show it spending a
little more on hard tasks, and getting more right for it. The savings it is
built for show up on tasks with large reads and outputs. The eval suite below
is built to measure them, and results will be added as they come in.

## Evals

`skills/plumb/evals/` has five cases. Each builds a small Python repository
with a real git history in which one commit quietly broke money rounding:

| Case | Checks that |
|------|-------------|
| `small-rename-stays-small` | A small task stays small: callers updated, no unrelated reading, a short reply. |
| `regression-names-the-commit` | "Since when?" leads to history, read cheaply, and names the right commit. |
| `fixes-root-not-symptom` | The fix lands in the shared helper, not in the caller where the bug showed. |
| `full-report-when-asked` | A requested report is complete, with evidence, not cut short. |
| `rule-change-reaches-every-copy` | A rule changed in one file is also changed where it is duplicated. |

Run them with Claude Code 2.1.269 or later, from `skills/plumb/`:

```bash
claude plugin eval . --allow-tools Write,Edit,Bash --scaffold
```

## Compared with ponytail

plumb started as an answer to [ponytail](https://github.com/DietrichGebert/ponytail),
which does a lot right: the smallest complete change, reuse before writing,
never cutting validation or security. plumb keeps those rules and changes
three things:

- **No UI.** ponytail adds a band above the prompt and a status line. plumb
  adds nothing to the screen; `/plumb stats` shows the numbers when you ask.
- **Depth, not just restraint.** ponytail's levels change how strictly it
  limits work. plumb's levels change how far it is allowed to look, and it
  moves between them on evidence.
- **Input first.** ponytail mostly shapes the code that gets written. plumb
  also shapes what gets read, which is where most tokens go.

## Files

```text
skills/plumb/
├── SKILL.md              the skill (loaded when it triggers)
├── references/deep.md    loaded at deep depth
├── references/report.md  loaded when a report is asked for
├── scripts/stats.py      /plumb stats
├── dev/build-fixture.sh  builds the eval repository
└── evals/                one folder per case
```

## License

MIT
