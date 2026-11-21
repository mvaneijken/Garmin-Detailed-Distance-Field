#!/usr/bin/env bash
# Runs the Connect IQ unit tests ((:test) annotated functions) in the simulator.
#
# Skips cleanly while the code base has no tests yet (roadmap phase 1 adds them).
# EXPERIMENTAL: running the simulator headless under Xvfb on GitHub-hosted Ubuntu runners has not
# been verified yet; the first run with real tests must confirm the required system packages.
#
# Usage: tools/ci/run-unit-tests.sh --source <dir> --out <dir> --key <key.der> --device <id>
set -euo pipefail

source_dir=''; out_dir=''; key_file=''; device=''
while [ $# -gt 0 ]; do
  case "$1" in
    --source) source_dir="$2"; shift 2 ;;
    --out) out_dir="$2"; shift 2 ;;
    --key) key_file="$2"; shift 2 ;;
    --device) device="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

summary="${GITHUB_STEP_SUMMARY:-/dev/null}"

if ! grep -rqs '(:test)' "$source_dir/source" "$source_dir"/source-* 2>/dev/null; then
  echo "No (:test) functions found - unit tests skipped."
  printf '\n## Unit tests\n\nSkipped: no `(:test)` functions in the code base yet.\n' >> "$summary"
  exit 0
fi

mkdir -p "$out_dir"
test_prg="$out_dir/unit-test-$device.prg"
monkeyc -f "$source_dir/monkey.jungle" -d "$device" -o "$test_prg" -y "$key_file" --unit-test

log="$out_dir/unit-test-$device.log"
# The simulator must be running before monkeydo can load the program into it.
xvfb-run --auto-servernum bash -c "
  connectiq &
  sim_pid=\$!
  sleep 15
  monkeydo '$test_prg' '$device' -t > '$log' 2>&1
  status=\$?
  kill \$sim_pid || true
  exit \$status
" || { cat "$log"; echo "::error::Unit tests failed on $device"; exit 1; }

cat "$log"
printf '\n## Unit tests (%s)\n\n```\n%s\n```\n' "$device" "$(tail -n 40 "$log")" >> "$summary"
