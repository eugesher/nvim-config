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

# Create the cspell user dictionary OUTSIDE the nvim config tree so it
# survives future reinstalls (this script replaces $DEST wholesale).
# Guarded with a file-existence check so we never overwrite a populated
# dictionary on reinstall.
CSPELL_DIR="$HOME/.config/cspell"
CSPELL_USER_DICT="$CSPELL_DIR/user-words.txt"
mkdir -p "$CSPELL_DIR"
if [[ ! -e "$CSPELL_USER_DICT" ]]; then
  touch "$CSPELL_USER_DICT"
  echo "Created empty cspell user dictionary: $CSPELL_USER_DICT"
else
  echo "Kept existing cspell user dictionary: $CSPELL_USER_DICT"
fi

echo "Done. Launch nvim to let lazy.nvim install plugins."
echo "Note: cspell must be installed separately (npm install -g cspell)."
