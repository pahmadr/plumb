# Results

Every number here was measured, not estimated. Runs are single runs unless the
row says otherwise, so treat small differences as noise.

Token counts are the agent's total tokens as reported by Claude Code for the
subagent (input including cached context, plus output). Most of each figure is
the fixed cost of starting an agent in that repository (system prompt, project
instructions, memory), which no skill can change.

## 2026-11-23: two tasks on a real codebase

A private production codebase: Django API plus Next.js web app, accounting
domain. Model: Claude Opus 5.5.
Read-only tasks; nothing was changed.

### Product question (no code reading required)

"Some users want full accounting, others only invoices; the panel is too
complex and they leave. What do you suggest?"

| Configuration | Tokens | Tool calls | Time |
|---------------|-------:|-----------:|-----:|
| No skill      | 67,024 | 4 | 41 s |
| plumb         | 70,507 | 6 | 43 s |

Same recommendation from both. plumb made two more reads to back a claim about
the invoice form with the actual file, and named one case it had not checked.
The extra ~3.5k tokens are mostly the skill file itself.

### Multi-module investigation

"A customer bought 10 items and paid half. The user then edits the invoice and
later deletes or voids it. At each step, do the ledger, stock and the
customer's balance stay correct? Where can data be corrupted? Evidence from the
code."

| Configuration | Tokens | Tool calls | Time | Issues reported |
|---------------|-------:|-----------:|-----:|----------------:|
| ponytail (full) | 98,002 | 25 | 138 s | 2 |
| plumb           | 109,367 | 32 | 165 s | 4 |

Issues: both reported the deleted-receipt defect and payments accepted on a
draft invoice. Only plumb reported the cheque defect below and that voiding
an invoice does not give back a single-use discount code.

Both found the main defect: deleting a receipt in the treasury left its journal
entry behind and stranded the invoice. plumb also found that the customer
statement ignored cheque payments, so an invoice half paid by cheque showed
the whole amount owed. Both defects were confirmed by reading the code and then
fixed, with tests that fail before the fix.

## 2026-11-23: the five eval cases, plumb vs no skill

The suite in `skills/plumb/evals/`, one run per case and configuration, each
on a fresh copy of the fixture repository. Model: Claude Opus 5.5. Graded by
the repository's final state, the tool calls made, and the reply.

| Case | No skill | plumb | Difference |
|------|---------:|------:|-----------:|
| small-rename-stays-small | 58,546 | 61,349 | +4.8% |
| rule-change-reaches-every-copy | 61,479 | 62,525 | +1.7% |
| fixes-root-not-symptom | 61,851 | 64,338 | +4.0% |
| regression-names-the-commit | 60,947 | 65,078 | +6.8% |
| full-report-when-asked | 66,740 | 71,621 | +7.3% |
| **Total** | **309,563** | **324,911** | **+5.0%** |

Quality:

- Both configurations passed the core checks on every case: right files
  changed, tests passing, the right commit named, nothing changed when told
  not to, both copies of the VAT rate updated.
- plumb did better on two cases. On `fixes-root-not-symptom` it noticed that
  the till receipt rounds VAT on its own and still printed the wrong total
  after the shared helper was fixed, and fixed that too; the run without the
  skill fixed only the helper. On `full-report-when-asked` it found the double
  rounding in `invoice_total` (one of the expected findings) and ended with a
  "not covered" section; the run without the skill did neither.
- Neither run read the 800-line catalogue file on the small rename.

Cost: plumb used 5% more tokens. About 2,000 of the extra tokens per run are
the skill file itself, plus `references/deep.md` on the two cases where it
went deep. The tasks were small enough that the baseline was already lean, so
there was little waste for plumb to remove.

## 2026-11-24: smaller skill file (v0.2.0)

`SKILL.md` cut from 8.6 KB to 3.0 KB (about 2,100 to 750 tokens), the same
rules each in one line; `references/deep.md` from 3.8 KB to 3.0 KB; the
description from about 110 to 50 words. Same five cases, fresh fixture copies,
one run each, compared with the no-skill runs above.

| Case | No skill | plumb 0.1 | plumb 0.2 | 0.2 vs no skill |
|------|---------:|----------:|----------:|----------------:|
| small-rename-stays-small | 58,546 | 61,349 | 59,197 | +1.1% |
| rule-change-reaches-every-copy | 61,479 | 62,525 | 62,346 | +1.4% |
| fixes-root-not-symptom | 61,851 | 64,338 | 62,546 | +1.1% |
| regression-names-the-commit | 60,947 | 65,078 | 63,264 | +3.8% |
| full-report-when-asked | 66,740 | 71,621 | 67,456 | +1.1% |
| **Total** | **309,563** | **324,911** | **314,809** | **+1.7%** |

The extra cost fell from 5.0% to 1.7%. Quality held: the fix again caught and
fixed the receipt's separate rounding, the report again found the double
rounding and ended with a "not covered" section, and the VAT change again
reached all three copies (and this time added a test for it).

## What these runs do and do not show

- They do not show plumb saving tokens. On every task so far it spent a
  little more: 1% to 12%; 1.7% on the eval suite with the smaller skill file.
- They do show the trade it is designed to make: on the investigation, the
  extra 11k tokens bought a second serious bug that would otherwise have
  surfaced later, at a far higher cost.
- The saving plumb aims for (small tasks staying small, bounded command
  output, no re-reads) needs long sessions with large files and outputs to
  show up. The eval fixture is small, and a fresh agent on it is already
  lean, so these runs cannot show it either way.

## How to reproduce

From `skills/plumb/`, with Claude Code 2.1.269 or later:

```bash
claude plugin eval . --allow-tools Write,Edit,Bash --scaffold
```

Each case builds a small Python repository with a git history (see
`dev/build-fixture.sh`) and runs once with the skill and once without. Add
results here with the date, the model and the number of runs.
