#!/usr/bin/env bash
set -euo pipefail

if [[ ${MSYSTEM:-} != UCRT64 ]]; then
  echo "install-deps.sh must run in an MSYS2 UCRT64 shell" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mapfile -t packages < <(sed -e 's/[[:space:]]*#.*//' -e '/^[[:space:]]*$/d' \
  "$script_dir/packages.txt")

# pacboy is provided by the small MSYS-level pactoys package. The
# setup-msys2 action can translate a `pacboy:` input internally, but a fresh
# installation does not guarantee that /usr/bin/pacboy exists for scripts.
pacman --sync --noconfirm --needed git pactoys
pacboy --sync --noconfirm --needed "${packages[@]}"

# Keep the published snapshot small; package metadata remains installed.
pacman --sync --clean --clean --noconfirm
rm -rf /var/cache/pacman/pkg/* /tmp/*
