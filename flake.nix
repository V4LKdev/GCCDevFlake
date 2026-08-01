{
  description = "Pinned GCC contributor development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShellNoCC {
            name = "gcc-contributor";

            # Helps expose incorrectly classified dependencies.
            strictDeps = true;

            # Avoid Nix's default hardening flags influencing GCC itself.
            hardeningDisable = [ "all" ];

            nativeBuildInputs = with pkgs; [
              # Bootstrap compiler and build tools
              bash
              gcc
              binutils
              gnumake
              git

              # GCC source and generated-file tooling
              autoconf269
              automake
              autogen
              guile
              libtool
              m4
              flex
              bison
              gettext
              texinfo
              gawk
              gperf
              perl
              python3

              # GCC testsuite
              dejagnu
              expect
              tcl

              # Debugging and patch preparation
              gdb
              patch
              patchutils
              diffutils
              file
              which

              # Standalone reproducer tooling
              cmake
              ninja
              pkg-config
            ];

            buildInputs = with pkgs; [
              gmp
              mpfr
              libmpc
              isl
              zlib
              zstd
            ];

            shellHook = ''
              # Remove common host contamination without removing Nix's
              # own compiler-wrapper variables.
              unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS
              unset LD_PRELOAD LD_LIBRARY_PATH
              unset ADA_INCLUDE_PATH ADA_OBJECT_PATH
              unset GCC_EXEC_PREFIX COMPILER_PATH

              # GCC's documentation recommends a POSIX-compatible shell.
              export CONFIG_SHELL=${pkgs.bash}/bin/bash
              export SHELL=${pkgs.bashInteractive}/bin/bash

              echo
              echo "GCC contributor shell"
              echo "System:    ${system}"
              echo "Workspace: $PWD"
              echo "Bootstrap: $(gcc --version | head -n1)"
              echo "Autoconf:  $(autoconf --version | head -n1)"
              echo "Automake:  $(automake --version | head -n1)"
              echo
              echo "Note: GCC requires Automake 1.15.1 when regenerating"
              echo "      Makefile.in files. The default shell supports normal"
              echo "      builds, compiler source changes and testsuite work."
              echo
            '';
          };
        }
      );

      formatter = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        pkgs.nixfmt-rfc-style
      );
    };
}
