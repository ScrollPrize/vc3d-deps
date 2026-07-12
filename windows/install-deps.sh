#!/usr/bin/env bash
set -euo pipefail

if [[ ${MSYSTEM:-} != UCRT64 ]]; then
  echo "install-deps.sh must run in an MSYS2 UCRT64 shell" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mapfile -t packages < <(sed -e 's/[[:space:]]*#.*//' -e '/^[[:space:]]*$/d' \
  "$script_dir/packages.txt")

pacboy --sync --noconfirm --needed "${packages[@]}"
pacman --sync --noconfirm --needed git

# Keep the published snapshot small; package metadata remains installed.
pacman --sync --clean --clean --noconfirm
rm -rf /var/cache/pacman/pkg/* /tmp/*

