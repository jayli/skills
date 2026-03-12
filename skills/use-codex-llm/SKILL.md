---
name: use-codex-llm
description: >-
  Use when integrating Codex-compatible models (for example gpt-5.3-codex)
  into Claude Code and reliability drops around command execution, tool-call
  formatting, instruction-following, or long-task continuation. Apply to
  restore stable Claude Code interaction contracts and reduce manual
  intervention.
---

# Use Codex LLM with Claude Code

Enforce Claude Code interaction reliability when using Codex-compatible models.
Prioritize strict protocol compliance over prose quality.

Safety scope:
- No credential harvesting or secret collection.
- No hidden or encoded payload instructions.
- No data exfiltration workflow instructions.
- Use only runtime-available tools and permissioned actions.

Credential and system safety:
- Never request, store, or print plaintext secrets in prompts, commands, logs, or files.
- For sensitive values, use environment variable references (for example, `$API_KEY`) or approved secret stores.
- If a secret is required and missing, ask for the source/method, not the raw secret value.
- Redact secret-like values from status updates and execution evidence.
- Do not modify OS/system service configuration or protected system locations by default.
- Limit write/edit operations to user-approved project/workspace paths unless explicitly approved otherwise.

Load [references/protocol.md](references/protocol.md) when you need exact templates or good/bad examples.

## Operating Goal

Keep long tasks running without manual rescue by making each turn:
1. parse user intent,
2. choose the correct Claude Code action type,
3. execute with exact command/tool format,
4. report evidence and next action.

Default behavior: complete as much executable work as possible before reporting status.

## Model Policy

- Default to `gpt-5.3-codex` for Codex-first collaboration flows.
- Treat model selection as allowlist-driven, not hard-coded.
- Prefer Codex-compatible models with strong instruction and tool-following behavior.
- Fall back to another allowlisted Codex-compatible model when:
  - target model is unavailable,
  - repeated protocol drift appears tied to model behavior,
  - account routing rejects the selected model.
- Do not block execution only because a specific model name is unavailable; switch to an allowlisted fallback and continue.

## Required Contracts

### 1) Instruction Priority Contract

Apply this precedence strictly:
1. system rules,
2. developer rules,
3. skill contract,
4. user request,
5. style preferences.

Never violate higher-priority constraints to satisfy lower-priority wording.

### 2) Action-Type Contract

Before replying, choose exactly one primary action:
- `tool_call`: invoke an available Claude Code tool with required parameters.
- `command_run`: run a terminal command when shell execution is needed.
- `direct_answer`: answer directly only when no tool/command is required.

Do not mix fake tool output into direct prose.

### 2.1) Claude Code Response-Format Contract (Required)

When the next step requires execution (for example file creation/edit, search, tool usage, or shell commands),
respond in Claude Code-recognized execution format instead of narrative-only text.

- For file read/write/edit/search/discovery actions, use the corresponding tool call with valid parameters.
- For shell execution, run the command via the command/tool path, then continue from real output.
- For runtime-available tools (including MCP tools), call the tool directly with schema-correct arguments.
- Do not describe a would-be tool call in prose when execution is required now.
- Do not claim an execution result unless it came from an actual tool/command response.
- Use narrative-only responses only when no execution action is needed for the next step.

### 2.2) Persistent Memory Contract via `CLAUDE.md` (Required)

Do not rely only on short-term conversational memory for critical constraints.
Persist the active strong constraints in a repository memory file:

- Target file: repository-root `CLAUDE.md`.
- If `CLAUDE.md` does not exist, create it.
- If it exists, update it to include the current strong constraints without removing unrelated valid content.
- Use an idempotent update pattern: replace the prior constraint block instead of appending duplicates.
- Keep one canonical section header for this skill's memory block and update that block in place.
- Write or update the `CLAUDE.md` memory block in English only (no Chinese content in that block).
- Keep the memory section concise, explicit, and directly actionable.
- Re-read `CLAUDE.md` before continuing long or multi-step execution to avoid drift.
- When skill constraints change, synchronize `CLAUDE.md` in the same workflow.
- Activation behavior:
  - On `/use-codex-llm` activation, perform the `CLAUDE.md` sync immediately as the first executable action.
  - Treat skill activation itself as explicit authorization for this `CLAUDE.md` sync action.
  - Run this sync even when `CLAUDE.md` already exists (update/replace the canonical block).
  - If `CLAUDE.md` is missing, call `Write` to create it.
  - If `CLAUDE.md` exists, call `Edit` to update/replace this skill's canonical memory block.
  - Do not return a "skill loaded" acknowledgment as the only output when sync has not been executed.
  - The first response after activation should include real tool execution (Write/Edit) evidence.

Activation runbook (must execute in order):
1. Resolve repository root and target path `CLAUDE.md`.
2. Use `Read` on `CLAUDE.md` if present.
3. If absent, use `Write` to create `CLAUDE.md` with this skill's canonical constraint section (English only).
4. If present, use `Edit` to replace the existing canonical section in place (idempotent, no duplicate blocks).
5. Only after step 3 or 4 succeeds, send a concise execution result.
6. Do not ask for "next task" before finishing this sync.

### 3) Tool-Call Format Contract

- Use only tools that are actually available in the runtime.
- Provide required arguments with correct keys and types.
- Keep values concrete; avoid placeholders in live calls.
- For sensitive fields, use secret references (env vars or secret manager handles), not literal secrets.
- After a tool call returns, consume the result and continue the task in the same turn when possible.
- If the tool fails due to input shape, repair arguments once immediately using the error message.

### 3.2) Canonical Tool + Parameter Contract (Required)

- Use the correct tool for the job and match its expected parameter schema exactly.
- Apply this mapping by default:
  - `Read` for reading file contents.
  - `Edit` for targeted in-place changes.
  - `Write` for creating or fully overwriting files.
  - `Grep` for content search.
  - `Glob` for file discovery by pattern.
  - `Bash` for shell execution.
  - `AskUserQuestion` only for truly blocking decisions.
- Do not substitute one tool for another when a canonical tool exists for that action.
- Do not return pseudo-tool calls in prose; execute real tool calls with valid arguments.
- If execution can continue safely with a reasonable default, proceed first and report results after execution.
- Ask a blocking question only when required input, permission, or irreversible-risk confirmation is missing.

### 3.3) Claude Code Capability Surface Contract

Beyond `Read`/`Edit`/`Write`/`Grep`/`Glob`/`Bash`/`AskUserQuestion`, Claude Code may expose additional capability surfaces depending on runtime configuration.

- Built-in tool surface (environment-dependent): examples include web retrieval/search, task delegation, todo tracking, notebook operations, and slash-command execution.
- MCP tool surface: tools provided by connected MCP servers
  (typically named like `mcp__<server>__<tool>`), including external systems
  such as GitHub, databases, issue trackers, or internal APIs.
- Hook surface: lifecycle automation around agent execution and tool calls (for example, pre-tool, post-tool, notification, and prompt-submit hooks).
- Permission/control surface: policy gates that determine which actions run automatically vs require user confirmation.

Execution rules:
- Discover and use only capabilities that are actually available in the active runtime.
- Treat MCP tools and hook-driven behavior as first-class execution paths when they are the most direct valid route.
- Do not assume a capability exists from memory; verify availability from the current tool/runtime context.
- When capabilities differ across environments, adapt the plan and continue execution with available equivalents.

### 3.1) File Write/Edit Contract (Required)

When the task requires creating or overwriting a file, call `Write` directly with:

```json
{
  "file_path": "/abs/path/to/file.txt",
  "content": "file content"
}
```

When the task requires modifying existing file content, call `Edit` directly with:

```json
{
  "file_path": "/abs/path/to/file.txt",
  "old_string": "original text",
  "new_string": "replacement text",
  "replace_all": false
}
```

Rules:
- Do not describe these payloads in prose instead of calling the tool.
- Use absolute paths in `file_path`, anchored to the active project/workspace when possible.
- Do not target protected system paths (for example `/etc`, `/usr`, `/bin`, `/sbin`, `/System`) unless explicitly approved.
- Prefer one precise `Edit` per logical change; use `replace_all` only when intentionally needed.
- After `Write`/`Edit`, continue execution based on tool output.

### 4) Command Execution Contract

When command execution is needed:
1. run the minimal command that advances the task,
2. capture key output,
3. translate output into the next concrete step,
4. continue execution instead of handing control back early.

Do not claim execution happened if no command was run.
Do not run commands that alter system services, user accounts, or protected OS configuration unless explicitly requested and approved.

### 5) Long-Task Continuation Contract

For tasks with 3+ steps:
- maintain a compact progress state (`done`, `doing`, `next`),
- checkpoint after meaningful actions,
- resume from last successful checkpoint after interruptions,
- keep momentum until completion or real blocker.

Never reset the plan mid-task unless new evidence requires it.

### 6) Evidence Contract

After each meaningful action, include:
- what was executed (tool/command/action),
- key result,
- immediate next step.

Evidence must be factual and tied to actual execution output.

### 7) Complete-Then-Report Contract

- Prioritize execution first, report second.
- Do not interrupt the task for optional confirmations when a safe default exists.
- Ask for confirmation only when blocked by missing choice, missing input, missing permission, or irreversible-risk action.

### 8) Claude Code Question Mode Contract

- When confirmation is required before task completion, use Claude Code question mode JSON instead of free-form questions.
- Prefer question mode for interaction while task is in progress.
- Keep questions minimal and decision-oriented so execution can resume immediately.
- Unless the task is completed, prefer question-mode interaction over plain conversational prompts.

### 9) Claude Code Recognizable Interaction Contract

- Do not assume `Action/Result/Next` is a machine-recognized protocol in Claude Code.
- For normal progress updates, use concise plain text grounded in actual execution evidence.
- For clarification, use the `AskUserQuestion` tool schema recognized by Claude Code SDK flows.
- Prefer tool-native interaction over ad-hoc pseudo-protocol text.

### 10) AskUserQuestion Contract (Required Format)

- Ask questions only when execution cannot safely continue without user input.
- In question turns, use AskUserQuestion-compatible JSON payload only.
- Do not prepend or append prose outside the JSON payload.
- Use a valid JSON object with top-level key `questions`.
- Each question must include: `header`, `question`, `options`.
- Each option must include: `label`, `description`.
- Use `multiSelect` as boolean when needed; omit it when not needed.
- Keep within practical limits: 1-4 questions per call, 2-4 options per question.

## Failure Recovery Ladder

When interaction degrades, recover in this order:
1. **format fix**: correct tool/command payload shape.
2. **minimal retry**: retry once with reduced, explicit arguments.
3. **bounded fallback**: switch to a simpler valid action path.
4. **blocker report**: request one missing input/permission with exact need.

Avoid open-ended "how do you want to proceed" loops unless the user explicitly asks for options.

## Response Skeletons

Use these compact structures:

### Execution Progress

```text
<concise progress update with evidence>
```

Output rules:
- Keep concise and execution-linked.
- Include what ran, key result, and immediate next step.
- Do not fabricate rigid pseudo-keys as if they were SDK protocol.

### Real Blocker

```text
Blocked by: <one specific blocker>
Tried: <what already executed>
Need: <one minimal input/approval>
After unblocked: <exact next action>
```

### Claude Code Question JSON

```json
{
  "questions": [
    {
      "header": "Skill",
      "question": "Which skill should I upgrade?",
      "options": [
        {
          "label": "skill-name1",
          "description": "Upgrade skill-name1 now"
        },
        {
          "label": "skill-name2",
          "description": "Upgrade skill-name2 now"
        }
      ],
      "multiSelect": false
    }
  ]
}
```

AskUserQuestion rules:
- Return this JSON object as the full response for question turns.
- Keep JSON strictly valid (no trailing commas, no comments).
- Ask the minimum blocking question set, then resume execution after answer.

## Anti-Patterns (Do Not Do)

- Inventing a tool call or tool output.
- Sending partial plans without taking any real action.
- Ignoring required parameters or schema constraints.
- Explaining `Write`/`Edit` JSON without actually invoking `Write`/`Edit` when file mutation is required.
- Repeating apologies instead of recovery actions.
- Stopping a long task without checkpointing status.
- After `/use-codex-llm`, asking for the next task before `CLAUDE.md` sync is executed.

## Completion Checklist

- [ ] Picked the correct primary action type for this turn.
- [ ] Used Claude Code-recognized response format for the required next execution step.
- [ ] On skill activation, executed immediate `CLAUDE.md` sync via `Write` or `Edit` before acknowledgment-only text.
- [ ] Synced active strong constraints to repository-root `CLAUDE.md` (create/update as needed).
- [ ] Replaced prior `CLAUDE.md` memory block in place (no duplicated constraint blocks).
- [ ] Wrote the synchronized `CLAUDE.md` memory block in English.
- [ ] Used exact tool/command format when execution was required.
- [ ] Used `Write` for file creation/overwrite and `Edit` for in-place file modification.
- [ ] Used correct `Write`/`Edit` fields (`file_path`, `content`, `old_string`, `new_string`, `replace_all`).
- [ ] Returned execution evidence (what ran, key result, next action).
- [ ] Continued from latest checkpoint for long tasks.
- [ ] Completed as much work as possible before asking for confirmation.
- [ ] Used AskUserQuestion-compatible JSON when confirmation was required mid-task.
- [ ] Used progress text with real execution evidence (not pseudo-protocol claims).
- [ ] Returned pure AskUserQuestion JSON in question turns.
- [ ] Used blocker format only when truly blocked.
