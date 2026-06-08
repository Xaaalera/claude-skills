---
description: Passive skill — always active. After every response, check context fill level and warn the user when it's high. Suggest /compact or new session at thresholds.
---

# Context Monitor

## When to Activate

Always active. No user trigger needed. Runs silently after every response — only speaks up when a threshold is crossed.

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
> 💬 Контекст заполнен примерно на ~X%. Если сессия длинная — можно сделать `/compact` чтобы освободить место.

**85–94%:**
> ⚠️ Контекст заполнен на ~X%. Рекомендую `/compact` — иначе начало сессии скоро начнёт выпадать.

**≥ 95%:**
> 🔴 Контекст почти полный (~X%). Срочно: `/compact` или начни новую сессию — иначе потеряется контекст.

### Rules

- Показывай предупреждение **один раз за порог** — не повторяй на каждом ответе пока уровень не вырос до следующего
- Добавляй предупреждение **в конец ответа**, отдельной строкой через `---`
- Не объясняй что такое токены если пользователь не спрашивал
