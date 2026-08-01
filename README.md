# GCCDevFlake

A pinned Nix development environment for building, testing, and debugging GCC from source.

The flake provides the bootstrap compiler, GCC build dependencies, testsuite tools, debuggers, and common reproducer tooling. The GCC source tree remains a normal editable Git checkout and is built out of tree.

## What this provides

* Pinned bootstrap GCC and Binutils
* GMP, MPFR, MPC, ISL, zlib, and zstd
* Autoconf 2.69 and GCC source-generation tools
* DejaGnu, Expect, and Tcl for the GCC testsuite
* GDB and patch-development utilities
* CMake and Ninja for standalone compiler reproducers
* `x86_64-linux` and `aarch64-linux` development shells
* Reduced host-environment contamination

This is a reproducible development shell, not a container or security sandbox.

## Requirements

Install Nix with flakes enabled.

## Enter the environment

```bash
git clone git@github.com:V4LKdev/GCCDevFlake.git
cd GCCDevFlake
nix develop
```

For a cleaner environment that discards most inherited variables:

```bash
nix develop -i \
  -k HOME \
  -k USER \
  -k TERM \
  -k COLORTERM \
  -k SSH_AUTH_SOCK \
  -k XDG_RUNTIME_DIR
```

The GCC checkout and generated directories are intentionally excluded from this repository.

## Clone GCC

The GitHub repository is a mirror. GCC's own Git server remains the authoritative upstream but might cause errors transmitting the entire repository.

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

Create the out-of-tree directories:

```bash
mkdir -p build-debug install-debug repro
```

For a development branch:

```bash
git -C gcc switch -c my-gcc-change upstream/master

(
  cd gcc
  ./contrib/gcc_update --touch
)
```

## Configure a fast development build

```bash
cd build-debug

../gcc/configure \
  --prefix="$(realpath ../install-debug)" \
  --enable-languages=c,c++ \
  --disable-bootstrap \
  --disable-multilib \
  --disable-nls \
  --disable-werror \
  --enable-checking=yes,extra
```

This is intended for compiler development and rapid iteration. It is not a replacement for GCC's complete bootstrap and regression-testing requirements before submitting a patch.

## Build

```bash
make -j"$(nproc)" \
  all-gcc \
  all-target-libgcc \
  all-target-libstdc++-v3 \
  all-target-libatomic
```

Install into the local workspace prefix:

```bash
make \
  install-gcc \
  install-target-libgcc \
  install-target-libstdc++-v3 \
  install-target-libatomic
```

The `libatomic` step is required by current GCC development versions, which may link through `libatomic_asneeded`.

## Smoke test

```bash
cat >/tmp/gcc-dev-smoke.cpp <<'EOF'
#include <iostream>

int main()
{
    std::cout << "GCC development compiler works\n";
}
EOF

./install-debug/bin/g++ \
  -std=c++23 \
  /tmp/gcc-dev-smoke.cpp \
  -o /tmp/gcc-dev-smoke

/tmp/gcc-dev-smoke
```

## Validate the flake

```bash
nix flake check
nix flake show
```

## Generated build files

The shell pins Autoconf 2.69, as required by GCC.

The currently available Automake version may be newer than GCC's required Automake 1.15.1 for regenerating checked-in `Makefile.in` files. Normal GCC source changes, compiler builds, and testsuite work do not require regenerating those files.

Use the exact upstream-required tool versions before modifying or regenerating GCC's Autotools-generated files.

## License

The files in this repository are available under the MIT License.

GCC itself is a separate project and is distributed under its own licensing terms.
