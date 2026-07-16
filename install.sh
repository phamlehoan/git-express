#!/usr/bin/env bash
# Install gx into a directory on PATH (default: ~/.local/bin)
# Also installs docs + hook templates into ~/.local/share/gx/ (or $XDG_DATA_HOME/gx)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$ROOT/bin/gx"
DOCS_SRC="$ROOT/docs"
HOOKS_SRC="$ROOT/hooks"
NAME="gx"

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
if [ -n "${GX_DATA_DIR:-}" ]; then
  DATA_DIR="$GX_DATA_DIR"
elif [ -n "${XDG_DATA_HOME:-}" ]; then
  DATA_DIR="$XDG_DATA_HOME/gx"
else
  DATA_DIR="$HOME/.local/share/gx"
fi
DOCS_DIR="${GX_DOCS_DIR:-$DATA_DIR/docs}"
HOOKS_DIR="${GX_HOOKS_DIR:-$DATA_DIR/hooks}"

if [ ! -f "$SRC" ]; then
  echo "[Error] Missing $SRC" >&2
  exit 1
fi

mkdir -p "$INSTALL_DIR"
chmod +x "$SRC"

if [ "${GX_LINK:-0}" = "1" ]; then
  ln -sfn "$SRC" "$INSTALL_DIR/$NAME"
  echo "[OK] Linked $INSTALL_DIR/$NAME -> $SRC"
else
  cp -f "$SRC" "$INSTALL_DIR/$NAME"
  chmod +x "$INSTALL_DIR/$NAME"
  echo "[OK] Installed $INSTALL_DIR/$NAME"
fi

# Docs (USAGE.md + images + translations)
if [ -d "$DOCS_SRC" ]; then
  rm -rf "$DOCS_DIR"
  mkdir -p "$DOCS_DIR"
  cp -R "$DOCS_SRC"/. "$DOCS_DIR"/
  echo "[OK] Docs → $DOCS_DIR"
else
  echo "[Warn] No docs/ folder found next to install.sh"
fi

# Hook templates (enable per repo with: gx hooks on)
if [ -d "$HOOKS_SRC" ]; then
  rm -rf "$HOOKS_DIR"
  mkdir -p "$HOOKS_DIR"
  cp -R "$HOOKS_SRC"/. "$HOOKS_DIR"/
  chmod +x "$HOOKS_DIR"/* 2>/dev/null || true
  echo "[OK] Hooks → $HOOKS_DIR"
else
  echo "[Warn] No hooks/ folder found next to install.sh"
fi

case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *)
    echo ""
    echo "[Hint] Add to PATH (pick your shell config):"
    echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
    echo ""
    echo "  # bash:  ~/.bashrc"
    echo "  # zsh:   ~/.zshrc"
    echo "  # Git Bash (Windows): ~/.bashrc"
    ;;
esac

if command -v gx >/dev/null 2>&1; then
  echo "[OK] Ready: $(command -v gx)  ($(gx --version))"
  echo "     Docs: gx docs | gx docs vi | gx docs ja"
  echo "     Hooks: gx hooks on  (per repo)"
else
  echo "[OK] Install done. Restart the shell (or source your rc file), then run: gx h"
fi
