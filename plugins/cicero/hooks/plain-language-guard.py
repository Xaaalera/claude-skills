#!/usr/bin/env python3
"""
Stop-hook: enforce CICERO communication rules on the assistant's reply to the user.

Language-agnostic engine. All language-specific data lives OUTSIDE this file:
  - plugins/cicero/hooks/dicts/_base.json  — cross-language ALLOW (proper nouns).
  - plugins/cicero/hooks/dicts/<lang>.json — shipped, English-only: `script` + which
    English terms to flag and how (`action`). No translations here (repo is English-only).
  - ~/.claude/cicero/dicts/<lang>.json     — the USER dictionary: Russian (etc.) values +
    the user's own terms. Merged over the shipped dict; user entries win.
  - ~/.claude/cicero/config.json           — {"language": "<lang>"} chosen by the user once.

Term actions (per entry):
  - translate : always use `value`; flag the raw English form.
  - gloss     : English is OK but must be explained in (parens) on first use.
  - allow     : foreign word is fine as-is; never flag.

Enforced principles (CICERO):
  12 Language  — reply in the USER's language; code/paths/identifiers stay English.
  2  Size      — concise; no wall of filler.
  3  Gloss     — no dump of untranslated jargon; a foreign term is translated or glossed.
  0  Readable  — governs all; short sentences, one idea each, understood in one pass.

Deterministic heuristic (no model call): catches the GROSS violations —
  (a) reply prose in a different script than the user's language,
  (b) `translate` terms appearing raw (the dict has a native word for them),
  (c) too many stray foreign words the dict doesn't cover, and
  (d) `gloss` terms used without their (parenthetical) explanation on first use.
It cannot judge subtle style; it stops the repeat offenders.
"""
import json, re, sys
from pathlib import Path

HOOK_DIR = Path(__file__).resolve().parent
PLUGIN_DICTS = HOOK_DIR / "dicts"
USER_ROOT = Path.home() / ".claude" / "cicero"
USER_CONFIG = USER_ROOT / "config.json"
USER_DICTS = USER_ROOT / "dicts"

# --- CICERO rules, embedded so the block message carries the actual law ---
CICERO = (
    "CICERO 0 (Readable first — governs all): minimize cognitive load; short sentences, one idea each, understood in ONE pass.\n"
    "CICERO 12 (Language): converse in the USER's language; only code/docs/identifiers stay English.\n"
    "CICERO 2 (Size to ask): concise; bullets for lists, plain sentences for reasoning; no filler.\n"
    "CICERO 3 (Gloss): gloss a term the user may not know on first use, briefly, without nesting the sentence."
)


def load_json(path):
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except Exception:
        return None


def load_input():
    try:
        return json.load(sys.stdin)
    except Exception:
        return {}


def text_of(msg):
    c = msg.get("message", {}).get("content", "")
    if isinstance(c, str):
        return c
    if isinstance(c, list):
        return " ".join(b.get("text", "") for b in c if isinstance(b, dict) and b.get("type") == "text")
    return ""


def transcript_messages(path):
    out = []
    try:
        with open(path) as f:
            for line in f:
                line = line.strip()
                if line:
                    out.append(json.loads(line))
    except Exception:
        pass
    return out


def strip_code(s):
    s = re.sub(r"```.*?```", " ", s, flags=re.S)      # fenced code
    s = re.sub(r"`[^`]*`", " ", s)                     # inline code
    s = re.sub(r"https?://\S+", " ", s)                # urls
    s = re.sub(r"\S*/\S*", " ", s)                     # paths
    s = re.sub(r"\S+\.(md|py|ts|tsx|js|json|sh|cls|scss|css|xml)\b", " ", s)  # filenames
    s = re.sub(r"\([^)]*\)", " ", s)                   # parenthetical glosses are OK -> drop
    return s


# Script families we distinguish. Beyond these three we don't enforce.
def script_counts(s):
    """Count characters per script family: latin, cyrillic, cjk (han + kana + hangul)."""
    lat = cyr = cjk = 0
    for ch in s:
        o = ord(ch)
        if "a" <= ch.lower() <= "z":
            lat += 1
        elif 0x0400 <= o <= 0x04FF:
            cyr += 1
        elif (0x3040 <= o <= 0x30FF) or (0x3400 <= o <= 0x9FFF) or (0xAC00 <= o <= 0xD7AF):
            cjk += 1
    return {"latin": lat, "cyrillic": cyr, "cjk": cjk}


def dominant_script(counts, floor=20):
    """The single script family that clearly dominates, or None if none clears `floor`."""
    name = max(counts, key=counts.get)
    if counts[name] >= floor and counts[name] > sum(v for k, v in counts.items() if k != name):
        return name
    return None


def detected_script(msgs):
    """User's dominant script from their last few real messages: latin / cyrillic / cjk / None."""
    total = {"latin": 0, "cyrillic": 0, "cjk": 0}
    seen = 0
    for m in reversed(msgs):
        if m.get("type") == "user":
            t = text_of(m)
            if t.strip() and not t.strip().startswith("<"):
                for k, v in script_counts(t).items():
                    total[k] += v
                seen += 1
                if seen >= 3:
                    break
    return dominant_script(total)


def lang_for_script(script):
    """Find a shipped dict whose `script` matches; return its language code (file stem)."""
    for f in sorted(PLUGIN_DICTS.glob("*.json")):
        if f.stem.startswith("_"):
            continue
        d = load_json(f)
        if isinstance(d, dict) and d.get("script") == script:
            return f.stem
    return None


def resolve_language(msgs):
    """Config language wins; else auto-detect from the user's script."""
    cfg = load_json(USER_CONFIG)
    if isinstance(cfg, dict) and isinstance(cfg.get("language"), str) and cfg["language"]:
        return cfg["language"]
    script = detected_script(msgs)
    if script and script != "latin":
        return lang_for_script(script)
    return None


def load_dictionary(lang):
    """Merge shipped <lang>.json over _base.json, then the user dict over that.
    Returns (script, terms) where terms maps lowercased word -> {action, value?}."""
    base = load_json(PLUGIN_DICTS / "_base.json") or {}
    shipped = load_json(PLUGIN_DICTS / f"{lang}.json")
    user = load_json(USER_DICTS / f"{lang}.json")

    if shipped is None and user is None:
        return None, None  # unknown language — caller creates a skeleton and passes

    terms = {}
    for word in base.get("allow", []):
        terms[word.lower()] = {"action": "allow"}
    for src in (shipped, user):
        if isinstance(src, dict):
            for word, spec in (src.get("terms") or {}).items():
                if isinstance(spec, dict) and spec.get("action"):
                    terms[word.lower()] = spec
    script = None
    for src in (shipped, user):
        if isinstance(src, dict) and src.get("script"):
            script = src["script"]
    return script, terms


def ensure_user_skeleton(lang, script):
    """First contact with a language we don't ship: drop an empty user dict to grow into."""
    try:
        USER_DICTS.mkdir(parents=True, exist_ok=True)
        path = USER_DICTS / f"{lang}.json"
        if not path.exists():
            path.write_text(json.dumps({"script": script or "", "terms": {}}, ensure_ascii=False, indent=2), encoding="utf-8")
    except Exception:
        pass


def main():
    data = load_input()
    # Prevent infinite loops: if we already blocked this turn, let it pass.
    if data.get("stop_hook_active"):
        sys.exit(0)
    msgs = transcript_messages(data.get("transcript_path", ""))
    if not msgs:
        sys.exit(0)

    lang = resolve_language(msgs)
    if not lang:
        sys.exit(0)  # no target language (English user, or unresolved) — nothing to enforce

    script, terms = load_dictionary(lang)
    if terms is None:
        ensure_user_skeleton(lang, detected_script(msgs))
        sys.exit(0)  # language we don't know yet — skeleton created, pass this turn
    if script not in ("cyrillic", "cjk"):
        sys.exit(0)  # script-mismatch checks only work for non-Latin targets; Latin targets can't be told from English by script

    # last assistant text
    assistant = ""
    for m in reversed(msgs):
        if m.get("type") == "assistant":
            assistant = text_of(m)
            break
    if not assistant.strip():
        sys.exit(0)

    # Derive the working sets from the merged terms.
    translate = {w: spec.get("value") for w, spec in terms.items() if spec.get("action") == "translate"}
    ok_raw = {w for w, spec in terms.items() if spec.get("action") in ("allow", "gloss")}
    gloss_terms = {w for w, spec in terms.items() if spec.get("action") == "gloss"}

    prose = strip_code(assistant)
    reasons = []

    # (a) script mismatch: reply prose is dominated by a script other than the target's
    counts = script_counts(prose)
    target_n = counts.get(script, 0)
    others = {k: v for k, v in counts.items() if k != script}
    worst = max(others, key=others.get)
    if others[worst] > target_n and others[worst] > 15:
        reasons.append(f"reply prose is mostly {worst}-script while the user's language is '{lang}' ({script})")

    # (b) `translate` terms appearing raw — suggest the translation when the dict has one
    low = prose.lower()
    hits = sorted(w for w in translate if re.search(r"(?<![\w-])" + re.escape(w) + r"(?![\w-])", low))
    if hits:
        shown = [f"{w}→{translate[w]}" if translate[w] else w for w in hits]
        reasons.append(f"untranslated jargon in '{lang}' prose: " + ", ".join(shown))

    # (c) heavy anglicism: many stray latin words not covered by the dictionary
    lat_words = [w.lower() for w in re.findall(r"[A-Za-z][A-Za-z-]{2,}", prose)]
    stray = sorted({w for w in lat_words if w not in ok_raw and w not in translate})
    if len(stray) > 8:
        reasons.append(
            f"{len(stray)} Latin-script words in '{lang}' prose not covered by the dictionary "
            "(gloss or translate them): " + ", ".join(stray)
        )

    # (d) `gloss` terms used raw — English is fine, but must be explained in (parens) on
    # first use. strip_code() drops parentheticals, so check the ORIGINAL reply: a gloss
    # term passes if it appears at least once as "term (...)"; flag it if it never does.
    orig_low = assistant.lower()
    unglossed = sorted(
        w for w in gloss_terms
        if re.search(r"(?<![\w-])" + re.escape(w) + r"(?![\w-])", low)
        and not re.search(re.escape(w) + r"[\w-]*\s*\([^)]*\)", orig_low)
    )
    if unglossed:
        reasons.append("gloss terms used without a (parenthetical) explanation: " + ", ".join(unglossed))

    if reasons:
        teach = (
            "\n\nThe flagged words above are dictionary candidates. After re-sending the fixed reply, "
            "ASK the user how to handle each one and WAIT for their answer — never auto-add: "
            "translate (always use the '" + lang + "' word), gloss (keep the foreign word + explain "
            "in parens), or allow (leave it). Record each chosen word in ~/.claude/cicero/dicts/" + lang + ".json."
        )
        out = {
            "decision": "block",
            "reason": (
                "Rewrite this reply before sending — it breaks the house voice:\n- "
                + "\n- ".join(reasons)
                + "\n\n" + CICERO
                + "\n\nRe-send in the user's language, plain and short; translate the jargon "
                "or gloss each foreign term in (parens). Keep code/paths/identifiers as-is."
                + teach
            ),
        }
        print(json.dumps(out, ensure_ascii=False))
        sys.exit(0)

    sys.exit(0)


if __name__ == "__main__":
    main()
