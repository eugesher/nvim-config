#!/usr/bin/env bash
# Installs the Neovim configuration from this repository into ~/.config/nvim.
# Any existing config is backed up to ~/.config/nvim.backup.<timestamp>.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_DIR/nvim"
DEST="$HOME/.config/nvim"

if [[ ! -d "$SRC" ]]; then
  echo "ERROR: source directory not found: $SRC" >&2
  exit 1
fi

# Back up existing config
if [[ -e "$DEST" || -L "$DEST" ]]; then
  BACKUP="${DEST}.backup.$(date +%Y%m%d_%H%M%S)"
  echo "Backing up existing config: $DEST -> $BACKUP"
  mv "$DEST" "$BACKUP"
fi

# Copy configuration
echo "Installing config: $SRC -> $DEST"
cp -r "$SRC" "$DEST"

echo "Done. Launch nvim to let lazy.nvim install plugins."
