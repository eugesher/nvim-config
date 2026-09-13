#!/usr/bin/env bash

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

sed -e 's/\r$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$SRC" |
  grep -v '^#' | grep -v '^$' >>"$WORDS" || true

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

SORTED="$TMPDIR_RUN/sorted"
LC_ALL=C sort -f -u "$WORDS" >"$SORTED"

ARRAY="$TMPDIR_RUN/array"
{
  if [[ ! -s "$SORTED" ]]; then
    echo 'words = []'
  else
    echo 'words = ['
    while IFS= read -r word; do
      printf '  "%s",\n' "$(printf '%s' "$word" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')"
    done <"$SORTED"
    echo ']'
  fi
} >"$ARRAY"

mkdir -p "$(dirname "$DEST")"

if [[ ! -f "$DEST" ]]; then
  {
    echo '# codebook — global dictionary and spell-check settings.'
    echo '# Project-level overrides go into codebook.toml at the project root.'
    echo 'dictionaries = ["en_us"]'
    cat "$ARRAY"
    echo 'flag_words = []'
    echo 'ignore_paths = ["**/node_modules/**", "**/dist/**", "**/coverage/**", "**/*.lock", "**/*.min.js"]'
    echo 'ignore_patterns = []'
    echo 'use_global = true'
  } >"$DEST"
  echo "Created $DEST with $(wc -l <"$SORTED") word(s)."
  exit 0
fi

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
