#!/bin/sh
# Project Control Kit installer — copies the kit into a target repo without
# overwriting anything that already exists. Usage: ./install.sh /path/to/repo
set -e
TARGET="$1"
[ -n "$TARGET" ] || { echo "usage: ./install.sh /path/to/repo"; exit 1; }
[ -d "$TARGET" ] || { echo "error: $TARGET is not a directory"; exit 1; }
SRC="$(cd "$(dirname "$0")" && pwd)"

copy_tree() {  # copy_tree <src-dir> <dest-prefix>
  find "$1" -type f | while read -r f; do
    rel="${f#"$1"/}"
    dest="$2/$rel"
    if [ -e "$dest" ]; then
      echo "  skip (exists): ${dest#"$TARGET"/}"
    else
      mkdir -p "$(dirname "$dest")"
      cp "$f" "$dest"
      echo "  add:           ${dest#"$TARGET"/}"
    fi
  done
}

copy_tree "$SRC/agents" "$TARGET/.claude/agents"
copy_tree "$SRC/skills" "$TARGET/.claude/skills"
copy_tree "$SRC/skills/bootstrap/templates/ai" "$TARGET/.ai"

# CLAUDE.md: create, or append the managed block if one isn't already present.
BLOCK="$SRC/skills/bootstrap/templates/CLAUDE.md"
if [ ! -e "$TARGET/CLAUDE.md" ]; then
  cp "$BLOCK" "$TARGET/CLAUDE.md"
  echo "  add:           CLAUDE.md"
elif grep -q "pc-kit:begin" "$TARGET/CLAUDE.md"; then
  echo "  skip (managed block already present): CLAUDE.md"
else
  { echo ""; cat "$BLOCK"; } >> "$TARGET/CLAUDE.md"
  echo "  append managed block: CLAUDE.md"
fi

echo ""
echo "Installed. Next:"
echo "  cd $TARGET"
echo "  claude            # restart Claude Code so agents/skills load"
echo "  > /bootstrap"
