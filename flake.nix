# HOW TO USE:
# 1. make a `profiles/` directory in your repo and add to .gitignore
# 2. nix develop --profile profiles/dev
# 3. done!
#
# the shell is completely safe from garbage collection and evaluates instantly
# due to Nix's native caching. if you want logs during build, add `-L` to 
# `nix develop`.
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }: let
    inputs = { inherit nixpkgs; };
    system = "x86_64-linux";

    pkgs = nixpkgs.legacyPackages."${system}";

    # or, if you need to add an overlay:
    # pkgs = import nixpkgs {
    #   inherit system;
    #   overlays = [
    #     (import ./nix/overlay.nix)
    #   ];
    # };

    # a text file containing the paths to the flake inputs in order to stop
    # them from being garbage collected
    pleaseKeepMyInputs = pkgs.writeTextDir "bin/.please-keep-my-inputs"
      (builtins.concatStringsSep " " (builtins.attrValues inputs));
  in {
    devShell."${system}" = pkgs.mkShellNoCC {
      buildInputs = [
        # needed because the binding generator just YOLOs a compiler and it must
        # be before the ARM compiler below to avoid being falsely detected
        pkgs.stdenv.cc
        # ARM compiler used by CI and generally approved
        (pkgs.callPackage ./nix/packages/gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux {})
        # needed for version info and such
        pkgs.git
        # checked for, not sure if needed
        pkgs.rsync

        # used for SITL (console and map modules must be manually loaded)
        pkgs.mavproxy

        (pkgs.python3.withPackages (p: [
          (p.callPackage ./nix/packages/empy {})
          p.pexpect
          p.setuptools
          p.future
          p.intelhex
          p.scipy
        ]))

        pleaseKeepMyInputs
      ];

      shellHook = ''
        # hack to work around https://github.com/ArduPilot/ardupilot/blob/14aeb831fb98c4f8d5e2283b10ac95624476fb40/libraries/AP_Scripting/wscript#L11
        export NIX_CFLAGS_COMPILE=" -Wno-error=maybe-uninitialized $NIX_CFLAGS_COMPILE"
      '';
    };
  };
}
