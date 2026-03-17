# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal Claude Code skills repository. Skills are modular capabilities that extend Claude Code's functionality, defined in Markdown files with YAML front matter.

## Skill Structure

Each skill resides in its own directory under `skills/<skill-name>/`:

```
skills/
├── <skill-name>/
│   ├── SKILL.md              # Main skill definition (required)
│   └── ...                   # Optional supporting files
```

### SKILL.md Format

```yaml
---
name: "skill-name"             # Unique identifier (kebab-case)
description: "What this skill does"  # Shown in skill listings
argument-hint: "[optional]"    # Optional: hint for arguments
user-invocable: true           # Optional: allows /skill-name invocation
---

# Skill content in Markdown...
```

## External Skills

External skills are installed from GitHub and tracked in `skills-lock.json`. They are stored in:
- `.claude/skills/` - for Claude Code
- `.agents/skills/` - for other agent tools

Install external skills by updating `skills-lock.json` and copying the skill files to both directories.

## Working with Skills

### Creating a New Skill

1. Create directory: `mkdir skills/<skill-name>`
2. Create `SKILL.md` with proper YAML front matter
3. Follow naming convention: kebab-case for skill names

### Modifying Skills

- Edit the `SKILL.md` file directly
- Test user-invocable skills with `/<skill-name>`
- Skills without `user-invocable: true` are triggered by context/conditions

### Plan-Based Skills

Some skills (like `planify`) use plan files for task state management:
- Plan files: `.claude/plan/plan.<skill-name>.<timestamp>.md`
- Format: Markdown with `[ ]` (todo), `[x]` (done), `[!]` (error) checkboxes
- The `planify` skill can upgrade other skills to use this pattern

## Common Operations

### List all skills

```bash
ls -la skills/
```

### Check skill details

```bash
cat skills/<skill-name>/SKILL.md
```

### Verify skills-lock.json

The lock file tracks external skill versions by hash:
- `computedHash`: SHA256 hash of skill content
- `source`: GitHub repository source
- `sourceType`: Currently only "github"

## Architecture Notes

### Skill Execution Flow

1. User invokes skill via `/skill-name` or context trigger
2. Claude Code reads the skill's `SKILL.md`
3. Skill instructions are loaded into context
4. Skill guides execution based on its defined logic

### Skill Types

1. **Simple Skills**: Single-purpose, execute in one flow (e.g., `commit`)
2. **Plan-Based Skills**: Multi-step tasks with persistence (e.g., `planify`)
3. **Conditional Skills**: Triggered by specific patterns (e.g., `fuck` on frustration)
4. **Meta Skills**: Modify or upgrade other skills (e.g., `claude-oil`, `planify`)

### Important Files

- `skills-lock.json`: External skill registry with content hashes
- `.gitignore`: Excludes `.claude/`, `.agents/`, `skills-lock.json`, plan files
- `LICENSE`: MIT license

## Testing Skills

There is no automated test suite. Test skills manually:

1. For user-invocable skills: run `/<skill-name>` in Claude Code
2. For conditional skills: trigger the specific condition
3. Verify YAML front matter parses correctly
4. Check that skill instructions are clear and actionable
