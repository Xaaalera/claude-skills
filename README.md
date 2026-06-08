# Claude Code Skills

My personal Claude Code skill library. I'm a frontend developer — most skills here are about React, CSS, and UI tooling, with a few extras for git workflow and media.

---

## Frontend — CSS

<table>
<tr><td><code>frontend-css_rem</code></td><td>CSS Units — Always use rem for all dimensional values. Apply this rule any time CSS, SCSS, or Tailwind styles are written or reviewed.</td></tr>
<tr><td><code>frontend-css_scss-modules</code></td><td>Use this skill any time styles are written or modified: creating a new component, writing CSS/SCSS, refactoring existing styles.</td></tr>
</table>

## Frontend — React

<table>
<tr><td><code>frontend-react_component-structure</code></td><td>Use this skill any time a new React component is created or an existing component's structure is reviewed.</td></tr>
</table>

## Git

<table>
<tr><td><code>git_commit</code></td><td>Use this skill whenever the user asks to commit, create a commit, push changes, or says something like "commit this", "let's commit", "make a commit". Splits all uncommitted changes into atomic logical commits — one logical concern per commit, each describing at most 2-3 actions.</td></tr>
</table>

## Media

<table>
<tr><td><code>media_dub</code></td><td>Dubbing and translation with ElevenLabs. Use when the user wants to dub, translate, or voiceover a video or audio file using their cloned voice.</td></tr>
<tr><td><code>media_video-editing</code></td><td>AI-assisted video editing workflows for cutting, structuring, and augmenting real footage. Covers the full pipeline from raw capture through FFmpeg, Remotion, ElevenLabs, fal.ai, and final polish in Descript or CapCut. Use when the user wants to edit video, cut footage, create vlogs, or build video content.</td></tr>
</table>

## Meta

<table>
<tr><td><code>meta_context-monitor</code></td><td>Passive skill — always active. After every response, check context fill level and warn the user when it's high. Suggest /compact or new session at thresholds.</td></tr>
<tr><td><code>meta_new-skill</code></td><td>Use this skill when creating a new skill file. Ensures consistent naming, structure, and placement.</td></tr>
<tr><td><code>meta_skills-language</code></td><td>Passive skill — always active. All content written to ~/.claude/skills/ must be in English only, regardless of the conversation language.</td></tr>
</table>
