---
description: Dubbing and translation with ElevenLabs. Use when the user wants to dub, translate, or voiceover a video or audio file using their cloned voice.
---

# Dubbing / Translation with ElevenLabs

## When to Activate

- User says "translate video", "dub", "voiceover", "make english version"
- User says "переведи видео", "озвучь", "дублируй", "сделай английскую версию"
- User wants to translate audio/video from one language to another with their own voice

## API Key

Read from environment: `ELEVENLABS_API_KEY`

## Voice

Read from environment: `ELEVENLABS_VOICE_ID`
Always use this voice_id for TTS generation unless the user specifies otherwise.

## Default Behavior

- Source language: auto-detect (usually Russian)
- Target language: English
- Voice: `ELEVENLABS_VOICE_ID` env var
- Preserve timings: yes
- Output: MP4 in same directory as input, suffix `_english`

## Workflow

### Step 1 — Submit dubbing job

```python
import os, requests, time, json

API_KEY = os.environ["ELEVENLABS_API_KEY"]

def dub_video(input_path: str, source_lang: str = "ru", target_lang: str = "en") -> str:
    """Submit video for dubbing. Returns dubbing_id."""
    with open(input_path, "rb") as f:
        resp = requests.post(
            "https://api.elevenlabs.io/v1/dubbing",
            headers={"xi-api-key": API_KEY},
            data={
                "source_lang": source_lang,
                "target_lang": target_lang,
                "num_speakers": 1,
                "watermark": False,
            },
            files={"file": (os.path.basename(input_path), f, "video/mp4")},
        )
    resp.raise_for_status()
    dubbing_id = resp.json()["dubbing_id"]
    print(f"Dubbing job submitted: {dubbing_id}")
    return dubbing_id
```

### Step 2 — Poll for completion

```python
def wait_for_dubbing(dubbing_id: str, timeout: int = 1800) -> None:
    """Poll until dubbing is done."""
    start = time.time()
    while time.time() - start < timeout:
        resp = requests.get(
            f"https://api.elevenlabs.io/v1/dubbing/{dubbing_id}",
            headers={"xi-api-key": API_KEY},
        )
        resp.raise_for_status()
        status = resp.json()["status"]
        print(f"Status: {status}")
        if status == "dubbed":
            return
        if status == "failed":
            raise RuntimeError("Dubbing failed")
        time.sleep(15)
    raise TimeoutError("Dubbing timed out")
```

### Step 3 — Download result

```python
def download_dubbed(dubbing_id: str, output_path: str, lang: str = "en") -> None:
    """Download dubbed video."""
    resp = requests.get(
        f"https://api.elevenlabs.io/v1/dubbing/{dubbing_id}/audio/{lang}",
        headers={"xi-api-key": API_KEY},
        stream=True,
    )
    resp.raise_for_status()
    with open(output_path, "wb") as f:
        for chunk in resp.iter_content(chunk_size=8192):
            f.write(chunk)
    print(f"Saved: {output_path}")
```

### Full pipeline

```python
import os, sys

input_path = sys.argv[1]  # e.g. /Users/roman/work/demo/demo-russian.mp4
base = os.path.splitext(input_path)[0]
output_path = base + "_english.mp4"

dubbing_id = dub_video(input_path, source_lang="ru", target_lang="en")
wait_for_dubbing(dubbing_id)
download_dubbed(dubbing_id, output_path)
print(f"Done: {output_path}")
```

## TTS — Generate any text with Roman's voice

```python
import os, requests

API_KEY = os.environ["ELEVENLABS_API_KEY"]
VOICE_ID = "PdZuKoacuPMa468q42s5"

def generate_voiceover(text: str, output_path: str) -> None:
    resp = requests.post(
        f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE_ID}",
        headers={"xi-api-key": API_KEY, "Content-Type": "application/json"},
        json={
            "text": text,
            "model_id": "eleven_turbo_v2_5",
            "voice_settings": {"stability": 0.5, "similarity_boost": 0.75}
        }
    )
    resp.raise_for_status()
    with open(output_path, "wb") as f:
        f.write(resp.content)
    print(f"Saved: {output_path}")
```

## Notes

- Roman's voice_id: `PdZuKoacuPMa468q42s5` — always use this
- For best results, use clean audio (minimal background noise)
- Supported languages: ru, en, es, fr, de, zh, ja, pt, it, pl, and more
