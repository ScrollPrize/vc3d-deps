#!/usr/bin/env bash
set -euo pipefail

if [[ $(uname -s) != Darwin || $(uname -m) != arm64 ]]; then
  echo "install-deps.sh requires an Apple Silicon macOS runner" >&2
  exit 1
fi
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required" >&2
  exit 1
fi
if [[ $(brew --prefix) != /opt/homebrew ]]; then
  echo "Expected the standard Apple Silicon Homebrew prefix /opt/homebrew" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
formulae=()
while IFS= read -r formula; do
  formulae+=("$formula")
done < <(sed -e 's/[[:space:]]*#.*//' -e '/^[[:space:]]*$/d' \
  "$script_dir/formulae.txt")

export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1
brew install "${formulae[@]}"
brew cleanup --prune=all
