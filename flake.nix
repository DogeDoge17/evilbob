{
  description = "evilbob scary bob";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    zig2nix = {
      url = "github:Cloudef/zig2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    zig2nix,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
      env = zig2nix.zig-env.${system} {
        inherit nixpkgs;
        zig = zig2nix.packages.${system}.zig-0_17_1;
      };
      depArchives = env.deriveLockFile ./build.zig.zon2json-lock {
        zig = env.zig;
        name = "evilbob-dependencies";
      };
      deps = pkgs.runCommand "evilbob-system-dependencies" {} ''
        mkdir -p "$out"
        for archive in ${depArchives}/*.tar.gz; do
          name=$(basename "$archive" .tar.gz)
          mkdir -p "$out/$name"
          tar -xzf "$archive" --strip-components=1 -C "$out/$name"
        done
      '';
      platformLibs = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux (with pkgs; [
        libx11
        libxkbcommon
        alsa-lib
        libpulseaudio
      ]);
      runtimePath = pkgs.lib.makeLibraryPath platformLibs;
    in {
      packages.default = pkgs.stdenv.mkDerivation {
        pname = "evilbob";
        version = "0.0.0";
        src = pkgs.lib.fileset.toSource {
          root = ./.;
          fileset = pkgs.lib.fileset.unions [
            ./build.zig
            ./build.zig.zon
            ./src
            ./assets
          ];
        };
        nativeBuildInputs =
          [env.zig pkgs.pkg-config pkgs.makeWrapper]
          ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [pkgs.autoPatchelfHook];
        buildInputs = platformLibs;
        dontConfigure = true;
        buildPhase = ''
          runHook preBuild
          export HOME="$TMPDIR"
          export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-global-cache"
          export ZIG_LOCAL_CACHE_DIR="$TMPDIR/zig-local-cache"
          zig build --system ${deps} -Doptimize=ReleaseFast --prefix "$out"
          runHook postBuild
        '';
        dontInstall = true;
        postFixup = pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
          wrapProgram "$out/bin/evilbob" --prefix LD_LIBRARY_PATH : ${runtimePath}
        '';
        meta.mainProgram = "evilbob";
      };

      apps.default = flake-utils.lib.mkApp {
        drv = self.packages.${system}.default;
      };
      apps.zig2nix = {
        type = "app";
        program = "${env.zig2nix}/bin/zig2nix";
      };

      devShells.default = pkgs.mkShell {
        packages = [env.zig env.zls env.zig2nix pkgs.pkg-config];
        buildInputs = platformLibs;
        shellHook =
          ''
            export ZIG_GLOBAL_CACHE_DIR="$PWD/.zig-cache-global"
            export ZIG_LOCAL_CACHE_DIR="$PWD/.zig-cache"
            mkdir -p "$ZIG_GLOBAL_CACHE_DIR/p" "$ZIG_LOCAL_CACHE_DIR"
            ${pkgs.coreutils}/bin/cp -rs --update=none ${depArchives}/. "$ZIG_GLOBAL_CACHE_DIR/p/"
          ''
          + pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
            export LD_LIBRARY_PATH="${runtimePath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
          '';
      };
    });
}
