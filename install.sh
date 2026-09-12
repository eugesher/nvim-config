#!/usr/bin/env bash
# Installs the Neovim configuration from this repository into ~/.config/nvim.
# Any existing config is backed up to ~/.config/nvim.backup.<timestamp>.
#
# $DEST is replaced wholesale, so everything that has to survive a reinstall
# lives outside it: the codebook dictionary (~/.config/codebook/codebook.toml),
# vim-dadbod-ui connections and saved queries (~/.local/share/nvim/db_ui) and
# sessions (~/.local/state/nvim/sessions). The http/ collections stay in the
# repository and are not copied.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_DIR/nvim"
DEST="$HOME/.config/nvim"

if [[ ! -d "$SRC" ]]; then
  echo "ERROR: source directory not found: $SRC" >&2
  exit 1
fi

# Neovim 0.12+ is required: the config relies on its APIs. The version output
# is read whole (no `| head`), so pipefail cannot trip over a closed pipe.
if ! command -v nvim >/dev/null 2>&1; then
  echo "ERROR: nvim not found in PATH. Install Neovim 0.12+ first:" >&2
  echo "  sudo snap install nvim --classic" >&2
  exit 1
fi
NVIM_VERSION="$(nvim --version 2>/dev/null || true)"
NVIM_VERSION="${NVIM_VERSION%%$'\n'*}"
if [[ ! "$NVIM_VERSION" =~ ^NVIM\ v([0-9]+)\.([0-9]+) ]]; then
  echo "ERROR: could not read the Neovim version (nvim --version printed: '$NVIM_VERSION')." >&2
  exit 1
fi
if ((BASH_REMATCH[1] == 0 && BASH_REMATCH[2] < 12)); then
  echo "ERROR: $NVIM_VERSION found, this config needs Neovim 0.12+." >&2
  exit 1
fi
echo "Found $NVIM_VERSION"

# Plugins are compiled on the first start (LuaSnip's jsregexp,
# telescope-fzf-native.nvim, treesitter parsers). Not fatal here: the config
# installs, and :checkhealth myconfig reports the gap again.
for TOOL in make cc; do
  if ! command -v "$TOOL" >/dev/null 2>&1; then
    echo "WARNING: $TOOL not found — plugin builds will fail (sudo apt install build-essential)." >&2
  fi
done

# Back up existing config
if [[ -e "$DEST" || -L "$DEST" ]]; then
  BACKUP="${DEST}.backup.$(date +%Y%m%d_%H%M%S)"
  echo "Backing up existing config: $DEST -> $BACKUP"
  mv "$DEST" "$BACKUP"
fi

# Copy configuration
echo "Installing config: $SRC -> $DEST"
mkdir -p "$(dirname "$DEST")"
cp -r "$SRC" "$DEST"

# Create the codebook dictionary OUTSIDE the nvim config tree so it survives
# future reinstalls. Guarded with a file-existence check so we never overwrite a
# populated dictionary on reinstall. The path is the one codebook-lsp reads
# (XDG_CONFIG_HOME, else ~/.config); the defaults match
# scripts/cspell-to-codebook.sh. `ignore_paths` takes globs: a bare
# "node_modules" matches only a file of that name.
CODEBOOK_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/codebook"
CODEBOOK_CONFIG="$CODEBOOK_DIR/codebook.toml"
mkdir -p "$CODEBOOK_DIR"
if [[ ! -e "$CODEBOOK_CONFIG" ]]; then
  cat >"$CODEBOOK_CONFIG" <<'TOML'
# codebook — global dictionary and spell-check settings.
# Project-level overrides go into codebook.toml at the project root.
dictionaries = ["en_us"]
words = []
flag_words = []
ignore_paths = ["**/node_modules/**", "**/dist/**", "**/coverage/**", "**/*.lock", "**/*.min.js"]
ignore_patterns = []
use_global = true
TOML
  echo "Created codebook dictionary: $CODEBOOK_CONFIG"
else
  echo "Kept existing codebook dictionary: $CODEBOOK_CONFIG"
fi

# An old cspell word list can be merged in.
OLD_WORDS="${XDG_CONFIG_HOME:-$HOME/.config}/cspell/user-words.txt"
if [[ -s "$OLD_WORDS" ]]; then
  echo "Found an old word list at $OLD_WORDS — merge it with scripts/cspell-to-codebook.sh"
fi

echo "Done. Next:"
echo "  1. Run nvim: lazy.nvim installs the plugins, Mason the language servers and tools"
echo "     (wait until :Mason shows every package installed)."
echo "  2. Run :checkhealth myconfig and fix whatever it reports."
