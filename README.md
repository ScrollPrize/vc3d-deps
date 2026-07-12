# VC3D CI dependencies

Prebuilt build environments for `ScrollPrize/villa`'s
`volume-cartographer` (VC3D) CI jobs.

Installing Qt, OpenCV, Ceres, CGAL, LLVM, and the sparse-solver stack is the
slowest part of a clean VC3D build. This repository installs those dependencies
once and publishes three platform-specific artifacts to GHCR:

| Target | Published artifact | How CI uses it |
| --- | --- | --- |
| Ubuntu 26.04, amd64 | `ghcr.io/scrollprize/vc3d-deps/linux:ubuntu-26.04` | Docker builder image |
| Windows, amd64 | `ghcr.io/scrollprize/vc3d-deps/windows:ucrt64` | MSYS2/UCRT64 snapshot (`.7z`) |
| macOS 15, arm64 | `ghcr.io/scrollprize/vc3d-deps/macos:15-arm64` | Homebrew dependency snapshot (`.tar.zst`) |

The moving platform tags above are convenient for PR CI. Every publication is
also tagged `sha-<commit>` so release jobs can pin an immutable input. For full
reproducibility, resolve and pin an OCI digest rather than a moving tag.

## Publishing

Each platform has a separate workflow. A push to `main` publishes only the
platform whose manifest, build script, or workflow changed. All three workflows
also support manual dispatch.

The repository package must be visible to `ScrollPrize/villa`, and the consuming
job needs `packages: read`. Publishing jobs use the repository `GITHUB_TOKEN`
and need `packages: write`; no long-lived registry credential is required.

## Consuming from `villa`

### Linux

The existing `volume-cartographer/scripts/ci.sh` can pull and run the image, or
the job can use it directly:

```yaml
permissions:
  contents: read
  packages: read

jobs:
  build:
    runs-on: ubuntu-24.04
    container:
      image: ghcr.io/scrollprize/vc3d-deps/linux:ubuntu-26.04
      credentials:
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    steps:
      - uses: actions/checkout@v4
      - working-directory: volume-cartographer
        run: |
          cmake --preset ci-release-tests-gcc -DVC_USE_CCACHE=ON
          ninja -C build/ci-release-tests-gcc
          ctest --preset ci-release-tests-gcc
```

### Windows

Pull the snapshot with ORAS, restore it, then run the build with the included
MSYS2 Bash. There is no package installation in the consuming job.

```yaml
permissions:
  contents: read
  packages: read

steps:
  - uses: actions/checkout@v4
  - uses: actions/checkout@v4
    with:
      repository: ScrollPrize/vc3d-deps
      path: vc3d-deps
  - uses: oras-project/setup-oras@v1
  - shell: pwsh
    env:
      GHCR_TOKEN: ${{ github.token }}
    run: |
      $env:GHCR_TOKEN | oras login ghcr.io -u '${{ github.actor }}' --password-stdin
      oras pull ghcr.io/scrollprize/vc3d-deps/windows:ucrt64 -o $env:RUNNER_TEMP
      & .\vc3d-deps\windows\restore.ps1 `
        -Archive "$env:RUNNER_TEMP\vc3d-windows-ucrt64.7z"
  - name: Configure, build, and test
    working-directory: volume-cartographer
    shell: C:\msys64\usr\bin\bash.exe -leo pipefail {0}
    env:
      MSYSTEM: UCRT64
      CHERE_INVOKING: '1'
      PATH: C:\msys64\ucrt64\bin;C:\msys64\usr\bin;${{ env.PATH }}
    run: |
      cmake --preset ci-windows-mingw -DVC_USE_CCACHE=ON
      ninja -C build/ci-windows-mingw
      ctest --test-dir build/ci-windows-mingw --output-on-failure
```

The example assumes this repository is checked out at `vc3d-deps`, for example
with `actions/checkout`'s `repository` and `path` inputs.

### macOS

The macOS snapshot is tied to the runner image and architecture in its tag.
Restore it only on `macos-15` arm64 runners.

```yaml
permissions:
  contents: read
  packages: read

steps:
  - uses: actions/checkout@v4
  - uses: actions/checkout@v4
    with:
      repository: ScrollPrize/vc3d-deps
      path: vc3d-deps
  - uses: oras-project/setup-oras@v1
  - shell: bash
    env:
      GHCR_TOKEN: ${{ github.token }}
    run: |
      printf '%s' "$GHCR_TOKEN" | oras login ghcr.io -u '${{ github.actor }}' --password-stdin
      oras pull ghcr.io/scrollprize/vc3d-deps/macos:15-arm64 -o "$RUNNER_TEMP"
      vc3d-deps/macos/restore.sh "$RUNNER_TEMP/vc3d-macos-15-arm64.tar.zst"
  - working-directory: volume-cartographer
    run: ./scripts/build_macos.sh --ccache
```

The restore helper adds the captured formula closure to Homebrew's standard
Apple Silicon prefix, `/opt/homebrew`, and relinks it. It refuses to run on the
wrong OS, architecture, or prefix. `HOMEBREW_NO_AUTO_UPDATE=1` should remain set
in the build job.

## Updating dependencies

- Linux packages: edit `linux/install-deps.sh`.
- Windows packages: edit `windows/packages.txt`.
- macOS formulae: edit `macos/formulae.txt`.

Keep these lists synchronized with VC3D's CMake configuration and packaging
requirements. Open a PR here first, let the new artifacts publish from `main`,
then update `villa` to consume the new immutable tag or digest.

## Why Windows and macOS are archives

[GitHub Actions container actions run only on Linux][container-actions]. GitHub
offers [custom VM images][custom-images] for larger Linux and Windows runners,
but not macOS, and the current `villa` workflows use standard hosted runners.
Native filesystem snapshots preserve the toolchains needed by NSIS and
`macdeployqt` without changing those runner types.

[container-actions]: https://docs.github.com/actions/concepts/workflows-and-actions/custom-actions#docker-container-actions
[custom-images]: https://docs.github.com/actions/how-tos/manage-runners/larger-runners/use-custom-images
