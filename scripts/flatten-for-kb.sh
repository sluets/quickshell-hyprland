#!/usr/bin/env bash
#
# flatten-for-kb.sh
#
# Recursively copies every file under a Quickshell config directory into
# a single flat folder, so it can be uploaded to a Claude Project's
# knowledge base (which doesn't preserve folder structure — everything
# has to be a flat list of uniquely-named files).
#
# See README.md's "Working with Claude / updating the knowledge base"
# section for the full workflow this script is part of — including why
# this exists, when to run it, and how it fits into handing this repo to
# a fresh Claude chat (e.g. after cloning from GitHub).
#
# Files with a unique name across the whole tree keep their original
# name. Files that collide (e.g. the several README.md files in this
# project) get renamed using their parent folder as a prefix, matching
# the convention already documented in this project:
#
#   services/README.md   -> services-README.md
#   assets/README.md     -> assets-README.md
#   notes/README.md      -> notes-README.md
#   testing/README.md    -> testing-README.md
#   README.md (at root)  -> PROJECT_README.md
#
# Usage:
#   ./scripts/flatten-for-kb.sh [source_dir] [dest_dir]
#
# Defaults:
#   source_dir = the repo this script lives in (one level up from
#                scripts/) — so it works out of the box no matter whose
#                machine or username it's run on
#   dest_dir   = ~/quickshell-project
#
# Re-run this any time you want the flat folder to reflect the current
# state of your real config — it wipes and rebuilds dest_dir each time,
# so it's always a clean mirror, never a stale accumulation of old files.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_SRC="$(cd "$SCRIPT_DIR/.." && pwd)"

SRC="${1:-$DEFAULT_SRC}"
DEST="${2:-$HOME/quickshell-project}"

if [ ! -d "$SRC" ]; then
    echo "Source directory not found: $SRC" >&2
    exit 1
fi

# Resolve to absolute paths so the string-stripping below is reliable
SRC="$(cd "$SRC" && pwd)"

echo "Source: $SRC"
echo "Dest:   $DEST"
echo ""

rm -rf "$DEST"
mkdir -p "$DEST"

# ---- Pass 1: count how many files share each basename across the tree ----
declare -A name_count
while IFS= read -r -d '' f; do
    base="$(basename "$f")"
    name_count["$base"]=$(( ${name_count["$base"]:-0} + 1 ))
done < <(find "$SRC" -type f -not -path '*/.git/*' -not -name '.*' -print0)

# ---- Pass 2: copy everything, renaming only where names collide ----
declare -A used_names
count=0
while IFS= read -r -d '' f; do
    base="$(basename "$f")"
    rel="${f#"$SRC"/}"
    parent_rel="$(dirname "$rel")"

    if [ "${name_count[$base]}" -gt 1 ]; then
        if [ "$parent_rel" = "." ]; then
            # File sits directly in the config root with no parent folder
            # to borrow a name from — use PROJECT_ instead.
            newname="PROJECT_${base}"
        else
            parent_name="$(basename "$parent_rel")"
            newname="${parent_name}-${base}"
        fi
    else
        newname="$base"
    fi

    # Safety net: if the rename itself still collides (two files named
    # the same thing in two identically-named parent folders), append a
    # number rather than silently overwriting one with the other.
    final="$newname"
    n=2
    while [ -n "${used_names[$final]:-}" ]; do
        if [[ "$newname" == *.* ]]; then
            final="${newname%.*}_${n}.${newname##*.}"
        else
            final="${newname}_${n}"
        fi
        n=$((n + 1))
    done
    used_names["$final"]=1

    cp "$f" "$DEST/$final"
    echo "  $rel  ->  $final"
    count=$((count + 1))
done < <(find "$SRC" -type f -not -path '*/.git/*' -not -name '.*' -print0)

echo ""
echo "Done — $count files flattened into $DEST"
echo "Upload everything in that folder to the project's knowledge base."
