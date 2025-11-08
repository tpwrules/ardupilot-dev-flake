# HOW TO USE:
# 1. make a `profiles/` directory in your repo and add to .gitignore
# 2. nix develop --profile profiles/dev
# 3. done!
#
# the shell is completely safe from garbage collection and evaluates instantly
# due to Nix's native caching. if you want logs during build, add `-L` to 
# `nix develop`.
{
  # inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  # ESP-IDF 5.3 series
  # inputs.esp32.url = "github:mirrexagon/nixpkgs-esp-dev/e740e017122636ac1dbce9c0e3d867b9947a1687";
  # inputs.esp32.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/master";
  inputs.nixpkgs.follows = "nix-ros-overlay/nixpkgs";  # IMPORTANT!!!

  inputs.gradle2nix.url = "github:tadfisher/gradle2nix/v2";
  inputs.gradle2nix.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs,  gradle2nix, nix-ros-overlay }: let
    inputs = { inherit nixpkgs gradle2nix nix-ros-overlay; };
    system = "x86_64-linux";

    # pkgs = nixpkgs.legacyPackages."${system}";

    # or, if you need to add an overlay:
    pkgs = import nixpkgs {
      inherit system;
      overlays = [
        nix-ros-overlay.overlays.default
        # (import ./nix/overlay.nix)
      ];
    };

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
          p.geopy
          p.pytest
          # fake library so that Tools/scripts/run_lua_language_check.py doesn't download binaries
          (p.buildPythonPackage {
            pname = "github_release_downloader";
            version = "0";
            format = "other";
            dontUnpack = true;
            buildPhase = ''
              mkdir -p $out/${p.python.sitePackages}/github_release_downloader/
              cat << EOF > $out/${p.python.sitePackages}/github_release_downloader/__init__.py
              def GitHubRepo(*args, **kwargs): pass
              def check_and_download_updates(*args, **kwargs): pass
              EOF
            '';
          })
        ]))

        pkgs.colcon
        # ... other non-ROS packages
        (with pkgs.rosPackages.humble; buildEnv {
          paths = [
            ros-core
            ament-cmake-core
            python-cmake-module

            ament-black
            ament-cmake
            ament-cmake-black
            ament-cmake-copyright
            ament-cmake-lint-cmake
            ament-cmake-pep257
            ament-cmake-pytest
            ament-cmake-python
            ament-cmake-uncrustify
            ament-cmake-xmllint
            ament-copyright
            ament-index-python
            ament-lint-auto
            ament-pep257
            ament-uncrustify
            ament-xmllint
            builtin-interfaces
            geographic-msgs
            geometry-msgs
            launch
            launch-pytest
            launch-ros
            # micro-ros-agent
            micro-ros-msgs
            rclpy
            rosgraph-msgs
            rosidl-default-generators
            rosidl-default-runtime
            sensor-msgs
            pkgs.socat
            std-msgs
            tf2-msgs

            (pkgs.rosPackages.humble.callPackage ./nix/packages/micro_ros_agent {
              microxrceddsagent = (pkgs.callPackage ./nix/packages/microxrceddsagent {
                microxrceddsclient = (pkgs.callPackage ./nix/packages/microxrceddsclient {
                  microcdr = (pkgs.callPackage ./nix/packages/microcdr {});
                });
                foonathan_memory = (pkgs.callPackage ./nix/packages/foonathan_memory {});
                fastdds = (pkgs.callPackage ./nix/packages/fastdds {
                  foonathan_memory = (pkgs.callPackage ./nix/packages/foonathan_memory {});
                });
                spdlog = (pkgs.callPackage ./nix/packages/spdlog {});
                fastcdr = (pkgs.callPackage ./nix/packages/fastcdr {});
              });
            })
            # ... other ROS packages
          ];
        })

        # must be 5.1 due to `setfenv` in libraries/AP_Scripting/tests/luacheck.lua
        pkgs.lua51Packages.luacheck
        # invoke in the correct way so that the --check argument works (upstream nixpkgs patch might be warranted?)
        (pkgs.writeShellScriptBin "lua-language-server" ''
          exec ${pkgs.lua-language-server}/share/lua-language-server/bin/lua-language-server --metapath=''${XDG_CACHE_HOME:-''$HOME/.cache}/lua-language-server/meta "''$@"
        '')

        # # esp32 stuff
        # (esp.esp-idf-esp32.override {
        #   rev = "cc3203dc4f087ab41b434afff1ed7520c6d90993";
        #   sha256 = "sha256-hcE4Tr5PTRQjfiRYgvLB1+8sR7KQQ1TnQJqViodGdBw=";
        # })
        # (esp.esp-idf-esp32s3.override {
        #   rev = "cc3203dc4f087ab41b434afff1ed7520c6d90993";
        #   sha256 = "sha256-hcE4Tr5PTRQjfiRYgvLB1+8sR7KQQ1TnQJqViodGdBw=";
        # })
        # pkgs.esptool
        # pkgs.cmake
        # pkgs.ninja

        (pkgs.callPackage ./nix/packages/microxrceddsgen {
          buildGradlePackage = gradle2nix.builders."${system}".buildGradlePackage;
        })

        pleaseKeepMyInputs
      ];
    };
  };
}
