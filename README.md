# GCCDevFlake

A pinned Nix development environment for building, testing and debugging GCC
from an editable source checkout.

The flake provides GCC build dependencies, testsuite tools, debugging tools and
standalone reproducer tooling. GCC itself remains a normal Git checkout and is
built out of tree.

## Supported environment

This repository currently provides and validates an `x86_64-linux` development
shell.

It is a development environment, not a container or security sandbox. The
development tools are pinned by `flake.lock`; the GCC source revision is pinned
separately through Git.

## Enter the environment

```bash
git clone git@github.com:V4LKdev/GCCDevFlake.git
cd GCCDevFlake
nix develop
```

## Clone GCC

```bash
git clone \
  --single-branch \
  --branch master \
  --no-tags \
  https://github.com/gcc-mirror/gcc.git gcc

git -C gcc remote rename origin mirror
git -C gcc remote add upstream https://gcc.gnu.org/git/gcc.git
git -C gcc -c http.version=HTTP/1.1 fetch upstream master
```

Create a development branch and prepare generated-file timestamps:

```bash
git -C gcc switch -c my-gcc-change upstream/master

(
  cd gcc
  ./contrib/gcc_update --touch
)
```

## Configure a development build

The validated Linux workflow uses the host system's native Binutils for the GCC
being built. This prevents host system files from being linked with runtime
paths injected by Nix's wrapped linker.

```bash
mkdir -p build-debug install-debug
cd build-debug

../gcc/configure \
  --prefix="$(realpath ../install-debug)" \
  --enable-languages=c,c++ \
  --disable-bootstrap \
  --disable-multilib \
  --disable-nls \
  --disable-werror \
  --enable-checking=yes,extra \
  --with-build-time-tools=/usr/bin \
  --with-as=/usr/bin/as \
  --with-ld=/usr/bin/ld
```

## Build

```bash
make -j"$(nproc)" \
  all-gcc \
  all-target-libgcc \
  all-target-libstdc++-v3 \
  all-target-libatomic
```

## Install locally

```bash
make \
  install-gcc \
  install-target-libgcc \
  install-target-libstdc++-v3 \
  install-target-libatomic
```

## Smoke test

```bash
cat >/tmp/gcc-dev-smoke.cpp <<'CPP'
#include <iostream>

int main()
{
    std::cout << "GCC dev compiler works\n";
}
CPP

../install-debug/bin/g++ \
  -std=c++23 \
  /tmp/gcc-dev-smoke.cpp \
  -o /tmp/gcc-dev-smoke

/tmp/gcc-dev-smoke
```

## Validate the flake

```bash
nix fmt
nix flake check
```

## License

The files in this repository are available under the MIT License.

GCC is a separate project distributed under its own licensing terms.
