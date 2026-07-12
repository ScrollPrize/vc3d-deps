#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "install-deps.sh must run as root" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  software-properties-common \
  unzip
add-apt-repository -y universe
apt-get update -y
apt-get install -y --no-install-recommends \
  build-essential \
  bzip2 \
  ccache \
  clang \
  cmake \
  file \
  flang-21 \
  gfortran \
  git \
  jq \
  libavahi-client-dev \
  libblosc-dev \
  libboost-program-options-dev \
  libboost-system-dev \
  libcgal-dev \
  libceres-dev \
  libclang-rt-21-dev \
  libcurl4-openssl-dev \
  libgmp-dev \
  libhwloc-dev \
  liblapack-dev \
  liblapacke-dev \
  liblz4-dev \
  libmpfr-dev \
  libomp-dev \
  libopenblas-dev \
  libopencv-contrib-dev \
  libopencv-dev \
  libscotch-dev \
  libscotchmetis-dev \
  libsuitesparse-dev \
  libtiff-dev \
  libzstd-dev \
  lld \
  llvm \
  mold \
  ninja-build \
  nlohmann-json3-dev \
  pkg-config \
  python3 \
  python3-venv \
  qt6-base-dev \
  wget \
  zlib1g-dev

ln -sf /usr/bin/flang-21 /usr/local/bin/flang

arch="$(uname -m)"
case "$arch" in
  x86_64) aws_arch=x86_64 ;;
  aarch64|arm64) aws_arch=aarch64 ;;
  *) echo "Unsupported architecture for AWS CLI: $arch" >&2; exit 1 ;;
esac

curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${aws_arch}.zip" \
  -o /tmp/awscli.zip
unzip -q /tmp/awscli.zip -d /tmp
/tmp/aws/install --update
rm -rf /tmp/aws /tmp/awscli.zip

rm -rf /var/lib/apt/lists/*

