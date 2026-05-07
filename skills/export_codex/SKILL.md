---
name: export_codex
description: Export current Codex CLI session conversation to project-local log files. MUST only trigger when explicitly invoked by skill name (/export_codex) — never auto-trigger.
user-invocable: true
---

# export_codex

This skill is only for Codex CLI sessions.

**IMPORTANT: This skill must ONLY be triggered when the user explicitly invokes it by name (`/export_codex`). Do not auto-trigger or context-trigger this skill under any circumstances.**

## Purpose

Export current-session dialogue (user + assistant) after the latest `/clear` marker into:

`.codex/logs/YYYY-MM-DD-0001.txt`

`0001` increments automatically per day.

## Run

From project root:

```bash
python3 .codex/skills/export_codex/export_session.py
```

Optional:

```bash
python3 .codex/skills/export_codex/export_session.py --session /absolute/path/to/rollout-xxxx.jsonl
```

## Notes

- Reads source session files from `~/.codex/sessions`.
- If no `/clear` marker is found in the current session log, it exports from the first message in that session.
- Output is plain text and includes timestamp + role for each message.
