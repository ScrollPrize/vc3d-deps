#!/usr/bin/env bash
set -euo pipefail

archive=${1:?usage: restore.sh <vc3d-macos-15-arm64.tar.zst>}
formulae_manifest="${archive%.tar.zst}-formulae.txt"

if [[ $(uname -s) != Darwin || $(uname -m) != arm64 ]]; then
  echo "The VC3D macOS snapshot requires an Apple Silicon macOS runner" >&2
  exit 1
fi
if [[ ! -f $archive ]]; then
  echo "Snapshot not found: $archive" >&2
  exit 1
fi
if [[ ! -f $formulae_manifest ]]; then
  echo "Snapshot formula manifest not found: $formulae_manifest" >&2
  exit 1
fi
if ! command -v brew >/dev/null 2>&1 || [[ $(brew --prefix) != /opt/homebrew ]]; then
  echo "Expected Homebrew at /opt/homebrew" >&2
  exit 1
fi

zstd -dc "$archive" | sudo tar -xf - -C /opt/homebrew

export HOMEBREW_NO_AUTO_UPDATE=1
formulae=()
while IFS= read -r formula; do
  [[ -z $formula ]] && continue
  formulae+=("$formula")
done < "$formulae_manifest"

if ((${#formulae[@]} == 0)); then
  echo "Snapshot formula manifest is empty: $formulae_manifest" >&2
  exit 1
fi

# Starting Homebrew once per formula dominates restore time for the full
# dependency closure. Both commands accept multiple formula arguments, so
# validate and link the whole snapshot with one Homebrew process each.
brew list --versions "${formulae[@]}" >/dev/null
brew link --overwrite --force "${formulae[@]}" >/dev/null

echo "Restored VC3D macOS dependencies to /opt/homebrew"
