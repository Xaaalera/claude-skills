---
description: Use this skill whenever the user asks to commit, create a commit, push changes, or says something like "commit this", "let's commit", "make a commit". Splits all uncommitted changes into atomic logical commits — one logical concern per commit, each describing at most 2-3 actions.
---

## Current git state

!`git status`

!`git diff --stat HEAD`

!`git diff HEAD`

## Instructions

Analyze the changes above and split them into atomic logical commits. Rules:

1. **One logical concern per commit** — a single feature, a single refactor, a single fix. Never mix unrelated concerns in one commit.
2. **Commit message describes at most 2-3 actions** — if you need more words to describe it, the commit is too big.
3. **Use conventional commit prefixes:** `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, `test:`
4. **Order matters** — foundational changes (new files, new utilities, constants) go in earlier commits; consumers of those foundations go in later commits.
5. **Each commit must build** — never commit a state where an import references something not yet introduced in a prior commit.

### Steps to execute:

1. Unstage everything first: `git restore --staged .`
2. For each planned commit: stage exactly the right files with `git add <file1> <file2> ...`, then commit.
3. After all commits, run `git log --oneline -10` to confirm the result.
4. Show the final commit list to the user.

Do not ask for confirmation — analyze and execute the split directly.