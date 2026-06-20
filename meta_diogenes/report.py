#!/usr/bin/env python3
"""DIOGENES — token-spend analysis for a Claude Code session transcript.

Reads a session .jsonl transcript and reports where the tokens went:
  - session totals (input / output / cache-create / cache-read) + cost estimate
  - per-skill amortized cost  (load size x turns it stayed in context)
  - heaviest tool-results      (what got dumped into context)
  - heaviest output turns       (where the model generated the most)

Per-skill exact attribution is impossible: the API bills per turn over the whole
context, and a loaded skill is re-read (cached) every later turn. So skill cost is
an ESTIMATE = injected size x turns alive. Treat numbers as directional, not exact.

Usage:  python3 report.py [transcript.jsonl]
        (no arg -> newest transcript for the current working directory)
"""

import json
import os
import sys
import glob

# Per-million-token rates (USD). Opus 4.x defaults; edit if your model differs.
RATES = {"input": 15.0, "output": 75.0, "cache_write": 18.75, "cache_read": 1.50}

PROJECTS_DIR = os.path.expanduser("~/.claude/projects")


def find_transcript() -> str | None:
    cwd = os.getcwd()
    mangled = cwd.replace("/", "-").replace(".", "-")
    candidate = os.path.join(PROJECTS_DIR, mangled)
    pools = [candidate] if os.path.isdir(candidate) else []
    pools.append(PROJECTS_DIR)
    for base in pools:
        files = glob.glob(os.path.join(base, "**", "*.jsonl"), recursive=True)
        if files:
            return max(files, key=os.path.getmtime)
    return None


def block_text(content) -> str:
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for block in content:
            if isinstance(block, dict):
                parts.append(block.get("text") or json.dumps(block.get("content", "")))
            else:
                parts.append(str(block))
        return "".join(parts)
    return json.dumps(content)


def est_tokens(chars: int) -> int:
    return chars // 4  # rough: ~4 chars per token


def human(n: float) -> str:
    if n >= 1_000_000:
        return f"{n / 1_000_000:.1f}M"
    if n >= 1_000:
        return f"{n / 1_000:.1f}k"
    return str(int(n))


def main() -> None:
    path = sys.argv[1] if len(sys.argv) > 1 else find_transcript()
    if not path or not os.path.exists(path):
        print("DIOGENES finds no transcript to inspect. The barrel is empty.")
        sys.exit(1)

    totals = {"input": 0, "output": 0, "cache_write": 0, "cache_read": 0}
    turns = 0
    skills = []            # (name, load_turn, tool_use_id)
    tool_uses = {}         # id -> (name, hint)
    tool_results = []      # (bytes, tool_use_id)
    output_turns = []      # (output_tokens, turn, hint)

    for line in open(path, encoding="utf-8"):
        try:
            row = json.loads(line)
        except Exception:
            continue
        msg = row.get("message")
        if not isinstance(msg, dict):
            continue
        content = msg.get("content")
        usage = msg.get("usage")

        if msg.get("role") == "assistant" and usage:
            turns += 1
            totals["input"] += usage.get("input_tokens", 0)
            totals["output"] += usage.get("output_tokens", 0)
            totals["cache_write"] += usage.get("cache_creation_input_tokens", 0)
            totals["cache_read"] += usage.get("cache_read_input_tokens", 0)
            hint = ""
            if isinstance(content, list):
                for b in content:
                    if isinstance(b, dict) and b.get("type") == "text" and b.get("text"):
                        hint = b["text"].strip().replace("\n", " ")[:60]
                        break
            output_turns.append((usage.get("output_tokens", 0), turns, hint))

        if isinstance(content, list):
            for b in content:
                if not isinstance(b, dict):
                    continue
                if b.get("type") == "tool_use":
                    name = b.get("name", "?")
                    inp = b.get("input", {}) if isinstance(b.get("input"), dict) else {}
                    hint = (inp.get("file_path") or inp.get("command")
                            or inp.get("pattern") or inp.get("skill") or "")
                    if isinstance(hint, str):
                        hint = hint.replace("\n", " ")[:50]
                    tool_uses[b.get("id")] = (name, hint)
                    if name == "Skill":
                        skills.append((inp.get("skill", "?"), turns, b.get("id")))
                elif b.get("type") == "tool_result":
                    tool_results.append((len(block_text(b.get("content", ""))),
                                         b.get("tool_use_id")))

    cost = sum(totals[k] * RATES[k] for k in totals) / 1_000_000

    # ---- skill leaderboard: injected size x turns it stayed loaded ----
    res_by_id = {}
    for size, tid in tool_results:
        res_by_id[tid] = res_by_id.get(tid, 0) + size
    skill_rows = []
    for name, load_turn, tid in skills:
        load_tok = est_tokens(res_by_id.get(tid, 0))
        alive = max(0, turns - load_turn)
        skill_rows.append((name, load_tok, alive, load_tok * alive))
    skill_rows.sort(key=lambda r: r[3], reverse=True)

    # ---- heaviest tool-results, grouped by tool + hint ----
    heavy = {}
    for size, tid in tool_results:
        name, hint = tool_uses.get(tid, ("?", ""))
        key = (name, hint)
        heavy[key] = heavy.get(key, 0) + est_tokens(size)
    heavy_rows = sorted(heavy.items(), key=lambda kv: kv[1], reverse=True)[:8]

    output_turns.sort(reverse=True)

    # ---------------- print ----------------
    bar = "═" * 58
    print(f"\n{bar}")
    print("  🛢  DIOGENES — what did you squander on tokens?")
    print(f"  transcript: {os.path.basename(path)}  ·  {turns} assistant turns")
    print(bar)

    print("\n── THE BILL ──")
    print(f"  input        {human(totals['input']):>9}   ${totals['input']*RATES['input']/1e6:6.2f}")
    print(f"  output       {human(totals['output']):>9}   ${totals['output']*RATES['output']/1e6:6.2f}")
    print(f"  cache write  {human(totals['cache_write']):>9}   ${totals['cache_write']*RATES['cache_write']/1e6:6.2f}")
    print(f"  cache read   {human(totals['cache_read']):>9}   ${totals['cache_read']*RATES['cache_read']/1e6:6.2f}")
    print(f"  {'TOTAL':>13}              ≈ ${cost:6.2f}")

    print("\n── THE FATTENED SKILLS  (load × turns alive, estimate) ──")
    if skill_rows:
        for name, load, alive, amort in skill_rows:
            print(f"  {name:<34} {human(load):>6} ×{alive:<4} = {human(amort):>6}")
    else:
        print("  none loaded — Diogenes nods in rare approval.")

    print("\n── HEAVIEST TOOL-RESULTS  (what flooded the context) ──")
    for (name, hint), tok in heavy_rows:
        label = f"{name} {hint}".strip()
        print(f"  {human(tok):>6}  {label[:48]}")

    print("\n── FATTEST OUTPUT TURNS ──")
    for tok, turn, hint in output_turns[:6]:
        print(f"  {human(tok):>6}  turn {turn:<4} {hint}")

    print(f"\n{bar}")
    print("  Estimates only — the API bills per turn, not per skill.")
    print(bar + "\n")


if __name__ == "__main__":
    main()
