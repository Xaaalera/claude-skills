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
> 💬 Контекст заполнен примерно на ~X%. Если сессия длинная — можно сделать `/compact` чтобы освободить место.

**85–94%:**
> ⚠️ Контекст заполнен на ~X%. Рекомендую `/compact` — иначе начало сессии скоро начнёт выпадать.

**≥ 95%:**
> 🔴 Контекст почти полный (~X%). Срочно: `/compact` или начни новую сессию — иначе потеряется контекст.

### Rules

- **Всегда** добавляй в конец ответа строку с процентом заполненности — через `---`, без лишних слов: `контекст ~X%`
- Если порог пересечён — добавляй предупреждение следующей строкой после процента
- Показывай предупреждение **один раз за порог** — не повторяй пока уровень не вырос до следующего
- Не объясняй что такое токены если пользователь не спрашивал
