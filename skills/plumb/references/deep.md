# Deep depth: investigating without flooding the context

Deep does not mean "read everything". It means you are allowed to look in more
places, and you still pay for every line that comes back. Go from the cheapest
question that could settle the matter to the most expensive, and stop at the
first one that does.

## History

Start with one-line forms; open a full diff only for the one or two commits
that look responsible.

| Question | Cheapest command that answers it |
|----------|----------------------------------|
| What changed here recently? | `git log --oneline -15 -- <path>` |
| When did this line or function change? | `git log --oneline -L <start>,<end>:<path> \| grep -E '^[0-9a-f]{7,} '` or `git blame -L <start>,<end> <path>` |
| When was this symbol added or removed? | `git log --oneline -S '<symbol>' -- <path>` |
| What did one commit do to one file? | `git show <sha> --stat`, then `git show <sha> -- <path>` |
| What differs between a good and a bad version? | `git diff --stat <good> <bad>`, then the diff of the suspicious files only |
| Which commit broke it, with a runnable check? | `git bisect start <bad> <good>` then `git bisect run <command>`; finish with `git bisect reset` |

A commit message is a claim, not evidence. Before you name a commit as the
cause, look at what it changed in the relevant file.

Leave the working tree as you found it: no stash, checkout or reset of the
user's uncommitted changes. If you need another version of a file, read it with
`git show <sha>:<path>`. Bisecting moves the checkout, so use it only on a clean
tree or in a separate worktree.

## Other parts of the project

1. Search for the symbol, route, table or event name across the repository and
   list the files that hit (`files with matches`, not content).
2. Read only the hit lines of the files that matter.
3. If the list is long or spans several subsystems, give the sweep to a search
   subagent. Tell it the exact question, what you already ruled out, and to
   return a conclusion with `file:line` references, not file contents.

Typical places a cause hides outside the file in front of you: the serializer
or schema on the other side of an API call, a migration, a signal or hook, a
background job, a cached value, a feature flag, configuration that differs per
environment.

## When the first fix failed

Do not stack a second guess on top of the first. Undo the guess if it changed
nothing, then get evidence: reproduce the failure with the smallest command,
add one print or log at the boundary where good data turns bad, and read what
it actually says. One observation is cheaper than three theories.

## When to stop

Stop when you can state the cause in one sentence and point at the line, and
you have a check that fails before the fix and passes after. If you run out of
cheap questions and still cannot name the cause, say what you established, what
you ruled out, and the next step you would take with its rough cost, and let
the user choose.
