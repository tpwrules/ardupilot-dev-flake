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
  # ESP-IDF 4.x series
  inputs.esp32.url = "github:mirrexagon/nixpkgs-esp-dev/48413ee362b4d0709e1a0dff6aba7fd99060335e";
  inputs.esp32.inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05"; # needed for python 3.9 for mach-nix

  outputs = { self, nixpkgs, esp32 }: let
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

        # must be 5.1 due to `setfenv` in libraries/AP_Scripting/tests/luacheck.lua
        pkgs.lua51Packages.luacheck
        # invoke in the correct way so that the --check argument works (upstream nixpkgs patch might be warranted?)
        (pkgs.writeShellScriptBin "lua-language-server" ''
          exec ${pkgs.lua-language-server}/share/lua-language-server/bin/lua-language-server --metapath=''${XDG_CACHE_HOME:-''$HOME/.cache}/lua-language-server/meta "''$@"
        '')

        # esp32 stuff
        (esp32.packages."${system}".gcc-xtensa-esp32-elf-bin.override {
          version = "2021r2-patch5";
          hash = "sha256-jvFOBAnCARtB5QSjD3DT41KHMTp5XR8kYq0s0OIFLTc=";
        })
        (esp32.packages."${system}".gcc-xtensa-esp32s3-elf-bin.override {
          version = "2021r2-patch5";
          hash = "sha256-iqF6at8B76WxYoyKxXgGOkTSaulYHTlIa5IiOkHvJi8=";
        })
        esp32.packages."${system}".openocd-esp32-bin
        pkgs.esptool
        pkgs.cmake
        pkgs.ninja

        pleaseKeepMyInputs
      ];

    shellHook = let
      # mach-nix is used to set up the ESP-IDF Python environment.
      mach-nix-src = esp32.inputs.nixpkgs.legacyPackages."${system}".fetchFromGitHub {
        owner = "DavHau";
        repo = "mach-nix";
        rev = "c409df5347ef23f0bcba0aefc9a6345ef17b3441"; # last version
        hash = "sha256-gY8XkqNI21+Jkko6HigBv54s8od/SdyiSugM1yq/XII=";
      };

      mach-nix-src-fixed = pkgs.runCommand "patch" {} ''
        cp -r ${mach-nix-src}/ $out
        chmod -R u+w $out

        # patch idf-component-manager's illegal version requirements on the fly
        substituteInPlace $out/mach_nix/requirements.py \
          --replace-fail 'if distlib.markers.interpret(str(req.marker), context):' \
            'if distlib.markers.interpret(str(req.marker.replace(".*", "")), context):'
      '';

      mach-nix = import mach-nix-src-fixed {
        pypiDataRev = "570d3543eb53dad7d1eb0bb88ecbcf450bc69847"; # last version
        pypiDataSha256 = "sha256:1xhk812r208ppz325wxhzksqjalka6n1sdqgag5x8ilfj506pgr6";
        pkgs = esp32.inputs.nixpkgs.legacyPackages."${system}";
      };

      mach-nix-wrapper = mach-nix // {
        mkPython = args@{requirements, ...}: mach-nix.mkPython {
          # edit requirements to avoid pitfalls
          # gdbgui: deps we don't care about
          # cryptography: bad hash for version 3??? so we limit to max of ver 2
          requirements = builtins.replaceStrings [ "gdbgui" "cryptography"] [ "#gdbgui" "cryptography>=2.1.4,<3.0.0 #"] requirements;
        } // args;
      };

      esp-idf = (esp32.packages."${system}".esp-idf.overrideAttrs (old: {
        propagatedBuildInputs = []; # prevent the python from leaking
        installPhase = old.installPhase + ''
          # avoid whining about our slightly modified requirement list
          chmod u+w $out/requirements.txt
          truncate -s 0 $out/requirements.txt
        '';
      })).override {
        # from Tools/scripts/esp32_get_idf.sh
        rev = "6d853f0525b003afaeaed4fb59a265c8522c2da9";
        sha256 = "sha256-DBEgwKjBFhlmTDKJxrBxLQp1pCFgxwuGGNlpz90k/8A=";
        mach-nix = mach-nix-wrapper;
      };

      esp-python-wrapper = pkgs.writeShellScriptBin "esp-python-wrapper" ''
        PYTHONPATH=$IDF_PYTHON_ENV_PATH $IDF_PYTHON_ENV_PATH/bin/python "$@"
      '';
    in ''
      export IDF_PATH=${esp-idf}
      export IDF_PYTHON_ENV_PATH=$(readlink -f "$IDF_PATH"/lib/..)
      # used (we hope) exclusively by the IDF cmake stuff
      export PYTHON=${esp-python-wrapper}/bin/esp-python-wrapper
    '';
    };
  };
}
