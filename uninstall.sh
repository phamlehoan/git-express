#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
TARGET="$INSTALL_DIR/gx"

if [ -n "${GX_DATA_DIR:-}" ]; then
  DATA_DIR="$GX_DATA_DIR"
elif [ -n "${XDG_DATA_HOME:-}" ]; then
  DATA_DIR="$XDG_DATA_HOME/gx"
else
  DATA_DIR="$HOME/.local/share/gx"
fi
DOCS_DIR="${GX_DOCS_DIR:-$DATA_DIR/docs}"

if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
  rm -f "$TARGET"
  echo "[OK] Removed $TARGET"
else
  echo "[Info] Not found: $TARGET"
fi

if [ -d "$DOCS_DIR" ]; then
  rm -rf "$DOCS_DIR"
  echo "[OK] Removed docs $DOCS_DIR"
fi

# Remove empty parent data dir if nothing left
if [ -d "$DATA_DIR" ] && [ -z "$(ls -A "$DATA_DIR" 2>/dev/null || true)" ]; then
  rmdir "$DATA_DIR" 2>/dev/null || true
fi
