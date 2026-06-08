---
description: Passive skill — always active. After every response, check context fill level and warn the user when it's high. Suggest /compact or new session at thresholds.
---

# Context Monitor

## When to Activate

Always active. No user trigger needed. Shows context fill % after every response, warns when thresholds are crossed.

---

## Instructions

After every response, estimate how full the current context window is.

Use these thresholds:

| Fill level | Action |
|---|---|
| < 70% | Silent — do nothing |
| 70–84% | Soft warning |
| 85–94% | Strong warning |
| ≥ 95% | Critical warning |

### Warning messages

**70–84%:**
> 💬 Context ~X% full. Consider `/compact` if the session is long.

**85–94%:**
> ⚠️ Context ~X% full. Recommend `/compact` — early context will start dropping soon.

**≥ 95%:**
> 🔴 Context ~X% full. Do `/compact` or start a new session now — context loss imminent.

### Rules

- **Always** append a single line at the end of every response — after `---`, no extra words: `context ~X%`
- If a threshold is crossed — add the warning on the next line after the percentage
- Show each warning **once per threshold** — don't repeat until the level rises to the next one
- Don't explain what tokens are unless the user asks
