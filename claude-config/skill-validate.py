#!/usr/bin/env python3
"""PostToolUse(Write|Edit) hook: validate a SKILL.md after it is created/edited.

Encodes OUR accepted skill conventions (not the strict .skill packaging spec):
- valid YAML frontmatter block
- description present, a string, no angle brackets, <= 1024 chars
- only allowed frontmatter keys (catches stray keys like a leftover `origin`)
- if `name` is set, it must match the skill folder name

Deliberately does NOT require `name` and does NOT enforce kebab-case — our naming
convention uses underscores (`{domain}_{name}`) and Claude Code derives the name
from the folder. Stays silent when the skill is clean.
"""
import sys, os, re, json

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

path = (data.get('tool_input', {}).get('file_path')
        or data.get('tool_response', {}).get('filePath') or '')
if not path.endswith('SKILL.md') or '/.claude/skills/' not in path or not os.path.exists(path):
    sys.exit(0)

try:
    import yaml
except ImportError:
    sys.exit(0)  # no parser available — stay silent rather than block

folder = os.path.basename(os.path.dirname(path))
problems = []
content = open(path, encoding='utf-8').read()
match = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)

if not content.startswith('---') or not match:
    problems.append('no valid YAML frontmatter block')
else:
    try:
        frontmatter = yaml.safe_load(match.group(1))
        if not isinstance(frontmatter, dict):
            problems.append('frontmatter is not a mapping')
        else:
            allowed = {'name', 'description', 'license', 'allowed-tools', 'metadata', 'compatibility'}
            extra = set(frontmatter) - allowed
            if extra:
                problems.append('unexpected frontmatter key(s): ' + ', '.join(sorted(extra)))
            description = frontmatter.get('description')
            if not description:
                problems.append('missing description')
            elif not isinstance(description, str):
                problems.append('description must be a string')
            else:
                if '<' in description or '>' in description:
                    problems.append('description contains angle brackets (< or >)')
                if len(description) > 1024:
                    problems.append('description too long (%d > 1024)' % len(description))
            name = frontmatter.get('name')
            if isinstance(name, str) and name.strip() and name.strip() != folder:
                problems.append("name '%s' does not match folder '%s'" % (name.strip(), folder))
    except yaml.YAMLError as error:
        first_line = str(error).splitlines()[0] if str(error) else 'parse error'
        problems.append('invalid YAML in frontmatter: ' + first_line)

if problems:
    print(json.dumps({'systemMessage': '⚠️ skill-validate (%s): %s' % (folder, '; '.join(problems))}))
