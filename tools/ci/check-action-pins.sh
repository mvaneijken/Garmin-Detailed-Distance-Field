#!/usr/bin/env bash
# Fails when a workflow or composite action references a third-party action by a mutable tag or
# branch instead of a full 40-character commit SHA with a trailing "# vX.Y.Z" comment.
# Local actions (uses: ./...) are this repository's own code and are skipped.
#
# Usage: tools/ci/check-action-pins.sh [repository root]
set -euo pipefail

root="${1:-.}"
failures=0

while IFS= read -r file; do
  line_no=0
  while IFS= read -r line; do
    line_no=$((line_no + 1))
    if [[ "$line" =~ ^[[:space:]]*(-[[:space:]]*)?uses:[[:space:]]*([^[:space:]]+)@([^[:space:]]+)[[:space:]]*(#[[:space:]]*(.*))?$ ]]; then
      action="${BASH_REMATCH[2]}"
      ref="${BASH_REMATCH[3]}"
      comment="${BASH_REMATCH[5]:-}"
      if ! [[ "$ref" =~ ^[0-9a-f]{40}$ ]]; then
        echo "::error file=$file,line=$line_no::$action is pinned to '$ref', not a commit SHA."
        failures=$((failures + 1))
      elif ! [[ "$comment" =~ ^v[0-9]+\.[0-9]+\.[0-9]+ ]]; then
        echo "::error file=$file,line=$line_no::$action@$ref has no '# vX.Y.Z' version comment."
        failures=$((failures + 1))
      fi
    fi
  done < "$file"
done < <(find "$root/.github" -type f \( -name '*.yml' -o -name '*.yaml' \) | sort)

if [ "$failures" -gt 0 ]; then
  echo "$failures unpinned or uncommented action reference(s)."
  exit 1
fi
echo "All action references are pinned to a commit SHA with a version comment."
