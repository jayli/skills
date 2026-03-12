# Claude Code Protocol Reference for Codex Models

Use this file as a strict reference for execution behavior.
Copy patterns, not prose.

## 1) Turn Decision Flow

At each turn, decide in this order:
1. Is execution required now?
2. If yes, is it a `tool_call` or `command_run`?
3. If no, provide a concise `direct_answer`.

If execution is required, do not end with a plan-only response.
Prefer to finish executable work first, then report.

## 2) Good vs Bad Patterns

### Claude Code Recognizable Progress Format

Good:
- Use concise progress text linked to real execution output.
- Include: what ran, key result, and immediate next action.

Bad:
- Pretending `Action/Result/Next` is a machine-parsed Claude Code protocol.
- Reporting intent before execution when execution is possible.
- Emitting verbose status with no evidence.

### Tool Call

Good:
- Use an actually available tool.
- Pass required keys with concrete values.
- Read tool output before deciding next step.
- For file creation/overwrite, call `Write` directly.
- For file modification, call `Edit` directly.

Bad:
- Mentioning a tool in text but not invoking it.
- Using placeholder params like `<path>` in live calls.
- Ignoring tool error payload and repeating same malformed call.
- Describing `Write`/`Edit` payloads in prose when file edits are required.

### Command Run

Good:
- Run the smallest command that proves or advances state.
- Report key output and the immediate next action.

Bad:
- Claiming “I ran X” without output evidence.
- Running broad commands that do not reduce uncertainty.

## 2.1) Write/Edit JSON Templates

Use `Write` for new file content or full overwrite:

```json
{
  "file_path": "/abs/path/to/file.txt",
  "content": "file content"
}
```

Use `Edit` for targeted replacement in an existing file:

```json
{
  "file_path": "/abs/path/to/file.txt",
  "old_string": "original text",
  "new_string": "replacement text",
  "replace_all": false
}
```

Rules:
- Use absolute `file_path`.
- Keep `old_string` specific enough to avoid accidental edits.
- Set `replace_all` explicitly (`false` by default for safety).

### Direct Answer

Good:
- Use only when no execution is necessary.
- Keep concise and decision-oriented.

Bad:
- Giving theoretical guidance when user asked for execution.

## 3) Retry Templates

### Tool Shape Error Retry

```text
Action: repair tool-call payload using returned schema/error hints
Result: corrected argument keys/types and retried once
Next: continue with returned tool output
```

### Command Failure Retry

```text
Action: rerun command with minimal corrected flags/inputs
Result: previous error <brief>; corrected run output <brief>
Next: proceed to next dependent command or report real blocker
```

## 4) Long-Task Checkpoint Template

```text
Checkpoint:
- Done: <completed step ids>
- Doing: <current step>
- Next: <next concrete step>
```

Use after each major action in tasks with multiple dependent steps.

## 5) Blocker Report Template

```text
Blocked by: <single blocker>
Tried: <commands/tools already executed>
Need: <single missing input/approval>
After unblocked: <exact immediate command/tool action>
```

Do not ask multiple broad questions in blocker state.

When user input is required before completion, ask via Claude Code question-mode JSON.

## 6) Claude Code Question Mode JSON Template

```json
{
  "questions": [
    {
      "header": "选择 skill",
      "question": "请选择一个要升级的 Skill：",
      "options": [
        {
          "label": "skill-name1",
          "description": "升级 skill-name1"
        },
        {
          "label": "skill-name2",
          "description": "升级 skill-name2"
        }
      ],
      "multiSelect": false
    }
  ]
}
```

Rules:
- Use question JSON unless the task is already complete.
- Ask only the minimum set of blocking questions.
- Resume execution immediately after answers arrive.
- In question turns, output JSON only (no prose before/after).
- Keep keys exactly: `questions`, `header`, `question`, `options`, `label`, `description`, `multiSelect` (optional).
- Keep limits: 1-4 questions, and 2-4 options per question.

## 7) AskUserQuestion vs Progress Mode

Use Progress Mode when execution can continue:

```text
<concise progress update with evidence>
```

Use AskUserQuestion Mode when blocked on user decision:

```json
{
  "questions": [
    {
      "header": "选择 skill",
      "question": "请选择一个要升级的 Skill：",
      "options": [
        {
          "label": "skill-name1",
          "description": "升级 skill-name1"
        }
      ],
      "multiSelect": false
    }
  ]
}
```

## 8) Minimal Self-Check Before Sending

- Did I execute the required action type this turn?
- Did I include factual evidence from actual output?
- Did I keep the task moving without unnecessary handoff?
- If blocked, did I ask for only one minimal missing item?
- If task is unfinished and input is needed, did I use question JSON?
- If not blocked, did I provide concise progress with evidence and next action?
