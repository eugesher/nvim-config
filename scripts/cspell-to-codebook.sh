#!/usr/bin/env bash
# One-off migration: cspell user dictionary -> codebook dictionary.
#
# The old config kept its words in ~/.config/cspell/user-words.txt, one word per
# line. codebook keeps them in the `words` array of its global config,
# ~/.config/codebook/codebook.toml (task 21). This script merges the former into
# the latter without touching any other setting in the file.
#
# Safe to run repeatedly: the word list is merged, sorted and de-duplicated, so a
# second run leaves the file byte-for-byte identical. Missing input is not an
# error — there is simply nothing to convert.
#
# Both paths can be overridden, which is what the tests do:
#   CSPELL_WORDS=/tmp/words.txt CODEBOOK_CONFIG=/tmp/codebook.toml ./cspell-to-codebook.sh

set -euo pipefail

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
SRC="${CSPELL_WORDS:-$CONFIG_HOME/cspell/user-words.txt}"
DEST="${CODEBOOK_CONFIG:-$CONFIG_HOME/codebook/codebook.toml}"

if [[ ! -f "$SRC" ]]; then
  echo "No cspell dictionary at $SRC — nothing to convert."
  exit 0
fi

TMPDIR_RUN="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_RUN"' EXIT
WORDS="$TMPDIR_RUN/words"
: >"$WORDS"

# cspell's file is one word per line; blank lines and `#` comments are dropped.
sed -e 's/\r$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$SRC" |
  grep -v '^#' | grep -v '^$' >>"$WORDS" || true

# Words already in the config are kept. Only the top-level `words` array is
# read: `words` inside an [[overrides]] block belongs to that block.
extract_words() {
  awk '
    /^[[:space:]]*\[/ { top = 0 }
    NR == 1 { top = 1 }
    top && !inside && /^[[:space:]]*words[[:space:]]*=/ { inside = 1 }
    inside {
      line = $0
      while (match(line, /"[^"]*"/)) {
        word = substr(line, RSTART + 1, RLENGTH - 2)
        if (word != "") print word
        line = substr(line, RSTART + RLENGTH)
      }
      if (index($0, "]") > 0 && !(index($0, "[") > 0 && index($0, "]") < index($0, "["))) inside = 0
    }
  ' "$1"
}

if [[ -f "$DEST" ]]; then
  extract_words "$DEST" >>"$WORDS"
fi

# Case-insensitive de-duplication: codebook matches words without regard to case.
SORTED="$TMPDIR_RUN/sorted"
LC_ALL=C sort -f -u "$WORDS" >"$SORTED"

ARRAY="$TMPDIR_RUN/array"
{
  if [[ ! -s "$SORTED" ]]; then
    echo 'words = []'
  else
    echo 'words = ['
    while IFS= read -r word; do
      # TOML basic strings: backslash and quote have to be escaped.
      printf '  "%s",\n' "$(printf '%s' "$word" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')"
    done <"$SORTED"
    echo ']'
  fi
} >"$ARRAY"

mkdir -p "$(dirname "$DEST")"

if [[ ! -f "$DEST" ]]; then
  # First run on a machine that has no codebook config yet: write the same
  # defaults install.sh will create (task 28), with the converted words in place.
  {
    echo '# codebook — global dictionary and spell-check settings.'
    echo '# Project-level overrides go into codebook.toml at the project root.'
    echo 'dictionaries = ["en_us"]'
    cat "$ARRAY"
    echo 'flag_words = []'
    # Glob patterns, not plain names: a bare "node_modules" only matches a file
    # with that exact name, not what is inside the directory (verified against
    # codebook-lsp 0.3.42).
    echo 'ignore_paths = ["**/node_modules/**", "**/dist/**", "**/coverage/**", "**/*.lock", "**/*.min.js"]'
    echo 'ignore_patterns = []'
    echo 'use_global = true'
  } >"$DEST"
  echo "Created $DEST with $(wc -l <"$SORTED") word(s)."
  exit 0
fi

# The file exists: replace the top-level `words` array in place and leave every
# other line exactly as it was. Without such an array, it is inserted before the
# first table header (or appended).
OUT="$TMPDIR_RUN/out"
awk -v array_file="$ARRAY" '
  function emit_array(   line) {
    while ((getline line < array_file) > 0) print line
    close(array_file)
    emitted = 1
  }
  BEGIN { top = 1 }
  /^[[:space:]]*\[/ {
    if (top && !emitted) { emit_array(); print "" }
    top = 0
  }
  top && !inside && /^[[:space:]]*words[[:space:]]*=/ {
    inside = 1
    emit_array()
  }
  inside {
    if (index($0, "]") > 0) inside = 0
    next
  }
  { print }
  END { if (!emitted) emit_array() }
' "$DEST" >"$OUT"

if cmp -s "$OUT" "$DEST"; then
  echo "$DEST is already up to date ($(wc -l <"$SORTED") word(s))."
else
  cp "$OUT" "$DEST"
  echo "Updated $DEST — $(wc -l <"$SORTED") word(s) in the dictionary."
fi
