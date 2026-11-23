# Full reports

Use this when the user asked for a report, an investigation write-up, an audit
or "the full picture". The reader has not followed your tool calls; the report
must stand on its own.

## Shape

1. **Answer first.** One or two sentences: the conclusion, or the cause, or the
   recommendation. A reader who stops here should still be able to act.
2. **Findings.** One per item, most important first. Each has: what it is, the
   evidence (`file:line`, a commit hash, the command and what it printed), and
   why it matters to the user.
3. **What to do.** The options if there is a real choice, with your
   recommendation and its cost; otherwise the single next step.
4. **Not covered.** What you did not check and what you inferred without
   running it. Keep it specific; a vague disclaimer tells the reader nothing.

## Rules

- Complete, not padded. Include every finding that would change a decision;
  leave out the story of how you found it.
- Evidence beats adjectives. "Fails for amounts above 2^31 (`ledger.py:88`, no
  test)" instead of "may have overflow issues".
- Separate what you observed from what you concluded.
- Quote only the lines that prove the point, not whole files or diffs.
- Use a table only when findings share the same attributes (severity, location,
  fix). Use prose when the reasoning matters.
- Write in the user's language, and explain any term they did not use first.
