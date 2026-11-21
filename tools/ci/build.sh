#!/usr/bin/env bash
# Builds the data field with the Connect IQ compiler (monkeyc must be on PATH).
#
#   1. Exports the .iq for every product in manifest.xml - the same package that is uploaded to the
#      Connect IQ store - so a product that no longer compiles fails the build.
#   2. Compiles one .prg per representative tier device (tools/ci/tier-devices.txt) and reports its
#      size, so code growth on the memory-constrained tiers is visible on every pull request.
#
# Usage:
#   tools/ci/build.sh --source <dir> --out <dir> --key <developer_key.der> [--release] [--version <x.y.z>]
#
# The developer key signs the output. Pull-request builds use a throwaway key generated in the job;
# only the release workflow passes the real store signing key.
set -euo pipefail

source_dir=''
out_dir=''
key_file=''
release_mode='false'
version='0.0.0'
app_name='Garmin-Detailed-Distance-Field'

while [ $# -gt 0 ]; do
  case "$1" in
    --source) source_dir="$2"; shift 2 ;;
    --out) out_dir="$2"; shift 2 ;;
    --key) key_file="$2"; shift 2 ;;
    --release) release_mode='true'; shift ;;
    --version) version="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

for required in source_dir out_dir key_file; do
  if [ -z "${!required}" ]; then
    echo "Missing --${required%_*}" >&2
    exit 2
  fi
done

command -v monkeyc >/dev/null || { echo "monkeyc is not on PATH" >&2; exit 2; }

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Every manifest product needs its device files (they come from the toolchain image).
devices_dir="${HOME}/.Garmin/ConnectIQ/Devices"
missing=()
while IFS= read -r product; do
  [ -d "$devices_dir/$product" ] || missing+=("$product")
done < <(grep -o 'iq:product id="[^"]*"' "$source_dir/manifest.xml" | sed 's/.*id="\([^"]*\)"/\1/')
if [ "${#missing[@]}" -gt 0 ]; then
  echo "::error file=manifest.xml::No device files for: ${missing[*]}. Download them with the SDK Manager and rebuild the toolchain image (tools/toolchain/Publish-CiqToolchainImage.ps1)."
  exit 1
fi
jungle="$source_dir/monkey.jungle"
mkdir -p "$out_dir/prg" "$out_dir/logs"

release_flag=()
if [ "$release_mode" = 'true' ]; then
  release_flag=(-r)
fi

summary="${GITHUB_STEP_SUMMARY:-/dev/null}"
warnings_total=0

run_monkeyc() {
  # $1 = log name, rest = monkeyc arguments. Fails the script when the compiler fails.
  local log="$out_dir/logs/$1.log"
  shift
  if ! monkeyc "$@" >"$log" 2>&1; then
    cat "$log"
    echo "::error::monkeyc failed ($(basename "$log")). Full log above."
    return 1
  fi
  local count
  count="$(grep -c 'WARNING' "$log" || true)"
  warnings_total=$((warnings_total + count))
  # Surface compiler warnings as annotations without failing the build (yet - see issue #6).
  # grep exits 1 on a clean log; under errexit + pipefail that must not fail the build.
  { grep 'WARNING' "$log" || true; } | sort -u | awk 'NR <= 50' | while IFS= read -r line; do
    echo "::warning::$line"
  done
}

echo "## Build ($([ "$release_mode" = 'true' ] && echo release || echo validation), version $version)" >> "$summary"

# 1. Full export for every manifest product.
iq_file="$out_dir/$app_name-$version.iq"
run_monkeyc export -f "$jungle" -e -o "$iq_file" -y "$key_file" -w "${release_flag[@]}"
echo "" >> "$summary"
echo "Exported \`$(basename "$iq_file")\` for $(grep -c 'iq:product id=' "$source_dir/manifest.xml") products." >> "$summary"

# 2. Per-tier device builds with sizes.
{
  echo ""
  echo "| Device | .prg size (bytes) |"
  echo "|---|---:|"
} >> "$summary"
while IFS= read -r device; do
  [ -z "$device" ] && continue
  case "$device" in \#*) continue ;; esac
  prg="$out_dir/prg/$device.prg"
  run_monkeyc "$device" -f "$jungle" -d "$device" -o "$prg" -y "$key_file" -w "${release_flag[@]}"
  echo "| $device | $(stat -c %s "$prg") |" >> "$summary"
done < "$script_dir/tier-devices.txt"

echo "" >> "$summary"
echo "Compiler warnings (all builds, not deduplicated): $warnings_total" >> "$summary"

if [ "$release_mode" = 'true' ]; then
  (cd "$out_dir" && sha256sum "$(basename "$iq_file")" > "$(basename "$iq_file").sha256")
fi
