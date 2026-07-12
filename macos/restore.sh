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
while IFS= read -r formula; do
  [[ -z $formula ]] && continue
  brew list --versions "$formula" >/dev/null
  brew link --overwrite --force "$formula" >/dev/null
done < "$formulae_manifest"

echo "Restored VC3D macOS dependencies to /opt/homebrew"
