# Claude Code Skills

My personal Claude Code skill library — the single source of truth for my skills.
I'm a frontend developer, so most skills are React/CSS/UI, plus a few for Salesforce, git, and media.

These flat skill folders are the only files I hand-edit. `sync-skills.sh` regenerates
`README.md` and a plugin **marketplace** (`.claude-plugin/marketplace.json` + `plugins/`) from them,
then commits and pushes. Projects pull skills from the marketplace instead of copying folders.

---

## Use globally (all my projects)

These folders live at `~/.claude/skills/` and load as user-scope skills in every project automatically.

## Pull into a specific project (and share with teammates)

Add to the project's committed `.claude/settings.json`, then run `/plugin install` or `/reload-plugins`:

```json
{
  "extraKnownMarketplaces": {
    "xaaalera": { "source": { "source": "github", "repo": "Xaaalera/claude-skills" } }
  },
  "enabledPlugins": {
    "frontend@xaaalera": true,
    "salesforce@xaaalera": true,
    "git@xaaalera": true
  }
}
```

Plugin skills are namespaced (e.g. `frontend:react_component-structure`), so they never collide
with a project's own skills (project skills win).

### Env variables (media skills)

Add to `~/.claude/settings.json`:

```json
{ "env": { "ELEVENLABS_API_KEY": "your-key-here", "ELEVENLABS_VOICE_ID": "your-voice-id-here" } }
```

---

## Frontend — CSS

<table>
<tr><td><code>frontend-css_rem</code></td><td>CSS Units — Always use rem for all dimensional values. Apply this rule any time CSS, SCSS, or Tailwind styles are written or reviewed.</td></tr>
<tr><td><code>frontend-css_scss-modules</code></td><td>Use this skill any time styles are written or modified: creating a new component, writing CSS/SCSS, refactoring existing styles.</td></tr>
</table>

## frontend-js

<table>
<tr><td><code>frontend-js_conventions</code></td><td>House JavaScript/TypeScript coding style — arrow functions, single quotes, full variable names, braces on all control structures, small readable functions. Use whenever writing or editing JavaScript or TypeScript (React, Node, or any JS/TS).</td></tr>
</table>

## Frontend — React

<table>
<tr><td><code>frontend-react_component-structure</code></td><td>Use this skill any time a new React component is created or an existing component is edited or reviewed.</td></tr>
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
<tr><td><code>meta_new-skill</code></td><td>Use this skill when creating a new skill file. Ensures consistent naming, structure, and placement. For iterative creation with evals and testing, use the skill-creator plugin instead.</td></tr>
</table>

## salesforce-apex

<table>
<tr><td><code>salesforce-apex_test-authoring</code></td><td>Author and maintain Apex unit tests to a strict house standard. Use WHENEVER you create or edit an Apex class (.cls), write or fix an Apex test, or set up Apex test data — every new Apex class must get a matching test class in the same change. Covers data factories, @TestSetup, Assert.* assertions, FLS/user-mode testing, REST resource mocking, and bulk/positive/negative coverage.</td></tr>
</table>

## salesforce-dx

<table>
<tr><td><code>salesforce-dx_mcp</code></td><td>Prefer the salesforce-dx MCP tools over raw `sf` CLI for ANY interaction with any Salesforce org — SOQL/Tooling queries, running Apex tests, deploying or retrieving metadata. Use whenever you query an org, run tests, or push/pull metadata.</td></tr>
</table>

## salesforce-lwc

<table>
<tr><td><code>salesforce-lwc_development</code></td><td>House rules for developing Salesforce Lightning Web Components (LWC) and Aura. Use whenever creating or editing an LWC/Aura bundle — a component .js controller, .html template, or .js-meta.xml — or any Salesforce-side frontend JS. Covers DOM access and styling conventions.</td></tr>
</table>
