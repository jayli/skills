#!/usr/bin/env bash
set -euo pipefail

# Idempotently sync a canonical use-codex-llm memory block into repo-root CLAUDE.md.
# Usage:
#   ./scripts/sync_claude_md.sh
#   ./scripts/sync_claude_md.sh /path/to/repo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT_ROOT="${1:-}"

if [[ -n "$INPUT_ROOT" ]]; then
  REPO_ROOT="$(cd "$INPUT_ROOT" && pwd)"
elif git -C "$SCRIPT_DIR" rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
elif git rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
else
  REPO_ROOT="$(pwd)"
fi

TARGET="$REPO_ROOT/CLAUDE.md"
BEGIN_MARKER="<!-- use-codex-llm:begin -->"
END_MARKER="<!-- use-codex-llm:end -->"

BLOCK_FILE="$(mktemp)"
trap 'rm -f "$BLOCK_FILE" "$TMP_FILE"' EXIT

cat >"$BLOCK_FILE" <<'EOF'
<!-- use-codex-llm:begin -->
## use-codex-llm memory block

This block is managed by `scripts/sync_claude_md.sh`. Update this block in place.

### Activation contract
- On `/use-codex-llm`, immediately sync this block before any "next task" prompt.
- Treat activation as explicit authorization for this sync.
- If `CLAUDE.md` exists, update this block in place.
- If `CLAUDE.md` does not exist, create it and write this block.

### Execution contract
- Use Claude Code-recognized execution format for file/tool/command actions.
- Execute first, then report evidence.
- Ask blocking questions only when execution cannot safely continue.

### File-memory contract
- Keep exactly one canonical use-codex-llm block (no duplicates).
- Keep this block in English.
- Use `Write` to create and `Edit` to update existing content.
<!-- use-codex-llm:end -->
EOF

if [[ ! -f "$TARGET" ]]; then
  cat >"$TARGET" <<'EOF'
# CLAUDE.md

EOF
fi

TMP_FILE="$(mktemp)"
TRIM_FILE="$(mktemp)"
trap 'rm -f "$BLOCK_FILE" "$TMP_FILE" "$TRIM_FILE"' EXIT

# Remove all previously managed blocks, then append one fresh canonical block.
awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" '
  $0 == begin { skip=1; next }
  $0 == end { skip=0; next }
  skip != 1 { print }
' "$TARGET" >"$TMP_FILE"

# Trim trailing blank lines from the remaining content.
awk '
  { lines[NR] = $0 }
  NF { last_non_empty = NR }
  END {
    if (last_non_empty < 1) { exit }
    for (i = 1; i <= last_non_empty; i++) { print lines[i] }
  }
' "$TMP_FILE" >"$TRIM_FILE"

{
  cat "$TRIM_FILE"
  echo
  echo
  cat "$BLOCK_FILE"
  echo
} >"$TARGET"

echo "Synced: $TARGET"
