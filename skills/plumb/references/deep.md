# Deep: look further, still pay for every line

Ask the cheapest question that could settle it first; stop at the first answer.

## History

| Question | Command |
|----------|---------|
| Recent changes here | `git log --oneline -15 -- <path>` |
| When did these lines change | `git blame -L <a>,<b> <path>` |
| When was a symbol added/removed | `git log --oneline -S '<symbol>' -- <path>` |
| What one commit did to one file | `git show <sha> --stat`, then `git show <sha> -- <path>` |
| Good vs bad version | `git diff --stat <good> <bad>`, then only suspicious files |
| Which commit, with a runnable check | `git bisect run <cmd>` on a clean tree, then `git bisect reset` |

A commit message is a claim; check the diff before naming the cause. Read old
versions with `git show <sha>:<path>`; never stash, checkout or reset the
user's work.

## Elsewhere in the project

List files that match the symbol, route, table or event; read only the hits.
Long or cross-subsystem list: give it to a search subagent with the exact
question and ask for `file:line` conclusions. Causes hide in: the other side of
an API, migrations, signals or hooks, background jobs, caches, feature flags,
per-environment config.

## A fix that failed

Undo the guess, reproduce with the smallest command, log at the boundary where
good data turns bad, and read what it says. Stop when you can name the cause
in one sentence, point at the line, and have a check that fails before the fix
and passes after. Otherwise report what you established, what you ruled out,
and the next step with its rough cost.
