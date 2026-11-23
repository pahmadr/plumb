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

## What these runs do and do not show

- They do not show plumb saving tokens. In both it spent a little more: 5% and
  12%.
- They do show the trade it is designed to make: on the investigation, the
  extra 11k tokens bought a second serious bug that would otherwise have
  surfaced later, at a far higher cost.
- The saving plumb aims for (small tasks staying small, bounded command
  output, no re-reads) needs tasks with large outputs to show up. The eval
  suite in `skills/plumb/evals/` is built for that and has not been run at
  scale yet.

## How to reproduce

From `skills/plumb/`, with Claude Code 2.1.269 or later:

```bash
claude plugin eval . --allow-tools Write,Edit,Bash --scaffold
```

Each case builds a small Python repository with a git history (see
`dev/build-fixture.sh`) and runs once with the skill and once without. Add
results here with the date, the model and the number of runs.
