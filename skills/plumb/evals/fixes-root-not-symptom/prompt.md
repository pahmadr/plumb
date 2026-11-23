---
tags: [plumb]
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash, Agent]
---

invoice_total([(10.50, 1)]) returns 11.44, it should be 11.45. Fix it.
