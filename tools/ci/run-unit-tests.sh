#!/usr/bin/env bash
# Runs the Connect IQ unit tests ((:test) annotated functions) in the simulator.
#
# Skips cleanly when the code base has no (:test) functions.
# The simulator runs headless under Xvfb in the toolchain image (verified locally with this script).
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

# One pass builds with the given jungle and runs the tests in the simulator.
run_pass() {
  local jungle="$1" tag="$2"
  local test_prg="$out_dir/unit-test-$tag$device.prg"
  monkeyc -f "$source_dir/$jungle" -d "$device" -o "$test_prg" -y "$key_file" --unit-test

  local log="$out_dir/unit-test-$tag$device.log"
  # The simulator must be running before monkeydo can load the program into it.
  # monkeydo exits with status 1 even when every test passed (SDK 9.3.0, Linux), so its exit status
  # is ignored: the verdict is the result line it prints ("PASSED (passed=..)" or "FAILED (..)").
  xvfb-run --auto-servernum bash -c "
    connectiq &
    sim_pid=\$!
    sleep 15
    monkeydo '$test_prg' '$device' -t > '$log' 2>&1 || true
    kill \$sim_pid || true
  " || true

  cat "$log"
  printf '\n## Unit tests (%s%s)\n\n```\n%s\n```\n' "$tag" "$device" "$(tail -n 40 "$log")" >> "$summary"
  if ! grep -q '^PASSED (' "$log"; then
    echo "::error::Unit tests ($tag$device) failed (no PASSED result line in the output above)"
    return 1
  fi
}

run_pass monkey.jungle ''
# The lap probe (roadmap 0.5) has its own tests, compiled in only by probe.jungle.
if [ -f "$source_dir/probe.jungle" ]; then
  run_pass probe.jungle 'probe-'
fi
