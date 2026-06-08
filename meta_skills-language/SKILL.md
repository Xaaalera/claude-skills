---
description: Passive skill — always active. All content written to ~/.claude/skills/ must be in English only, regardless of the conversation language.
---

# Skills Language Rule

## When to Activate

Always active. Applies whenever creating or editing any file inside `~/.claude/skills/`.

---

## Instructions

Any content written to `~/.claude/skills/**` must be in English:

- Skill descriptions in frontmatter
- Section titles and body text
- Comments, examples, code annotations
- README entries

The conversation language doesn't matter — if the user is speaking Russian, the reply can be in Russian, but the skill file content must be English.
