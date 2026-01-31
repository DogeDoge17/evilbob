{
  description = "evilbob";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};

      commonNative = with pkgs; [zig pkg-config];

      linuxLibs = with pkgs; [
        alsa-lib
        libxkbcommon
        wayland
        xorg.libX11
        xorg.libXrandr
        xorg.libXinerama
        xorg.libXcursor
        xorg.libXi
      ];

      darwinFrameworks = with pkgs.darwin.apple_sdk.frameworks; [
        Cocoa
        CoreAudio
        AudioToolbox
        CoreVideo
        IOKit
        OpenGL
      ];

      platformLibs =
        (pkgs.lib.optionals pkgs.stdenv.isLinux linuxLibs)
        ++ (pkgs.lib.optionals pkgs.stdenv.isDarwin darwinFrameworks);
    in {
      packages.default = pkgs.stdenv.mkDerivation {
        pname = "evilbob";
        version = "0.1.0";
        src = self;

        nativeBuildInputs = commonNative;
        buildInputs = platformLibs;

        dontConfigure = true;

        buildPhase = ''
          export HOME="$TMPDIR"
          export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-global-cache"
          export ZIG_LOCAL_CACHE_DIR="$TMPDIR/zig-local-cache"
          zig build -Doptimize=ReleaseSafe install --prefix "$out"
        '';

        installPhase = "true";
      };

      apps.default = flake-utils.lib.mkApp {
        drv = self.packages.${system}.default;
        exePath = "/bin/evilbob";
      };

      devShells.default = pkgs.mkShell {
        nativeBuildInputs = commonNative;
        buildInputs = platformLibs;
        shellHook = ''
          export ZIG_GLOBAL_CACHE_DIR="$PWD/.zig-cache-global"
          export ZIG_LOCAL_CACHE_DIR="$PWD/.zig-cache"
          mkdir -p "$ZIG_GLOBAL_CACHE_DIR" "$ZIG_LOCAL_CACHE_DIR"
        '';
      };
    });
}
