#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if ! command -v inotifywait >/dev/null 2>&1; then
  echo "inotifywait not found. Install it with: sudo apt-get install inotify-tools" >&2
  exit 1
fi

"$SCRIPT_DIR/sync_addon.sh"

echo "Watching for changes in $PROJECT_DIR ..."

inotifywait -m -r -e close_write,create,delete,move \
  --exclude '(/\.git/|/\.idea/|/\.vscode/|/scripts/)' \
  "$PROJECT_DIR" | while read -r _; do
  "$SCRIPT_DIR/sync_addon.sh"
  echo "---"
  echo "Resynced at $(date +%H:%M:%S)"
  echo "---"
  done
