{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  name = "weir";

  # sbtix = callPackage (fetchFromGitLab {
  #   owner = "teozkr";
  #   repo = "Sbtix";
  #   rev = "4ab0d2d24b27eb4f1a293e4328a0cd1975a483ac";
  #   sha256 = "178z2g8ayxv9vrar1vrwcdbxbdqlyjwhakjkfsc5nrk38v7nn9cz";
  # }) {};

  sbtix = callPackage /home/qb/projects/Sbtix {};

  sbtixLib = pkgs.callPackage "/home/qb/projects/Sbtix/plugin/nix-exprs/sbtix.nix" {};

  metals-emacs = stdenv.mkDerivation rec {
    name = "metals-emacs";
    version = "0.7.6";

    dep-name = "org.scalameta:metals_2.12:${version}";

    src = stdenv.mkDerivation {
      name = "metals-deps";

      buildCommand = ''
        mkdir -p $out/share/deps
        export COURSIER_CACHE=$out/share/deps
        coursier fetch ${dep-name}
      '';

      outputHashAlgo = "sha256";
      outputHashMode = "recursive";
      outputHash = "1yq826hp8740dvj1k9rgy12j7h12cpnycwjxavqvdpz44c4fk2rk";

      nativeBuildInputs = [ coursier ];
    };

    nativeBuildInputs = [ coursier makeWrapper ];

    buildCommand = ''
      mkdir -p $out/bin
      export COURSIER_CACHE=$src/share/deps
      coursier bootstrap \
      --mode offline \
      --java-opt -Xss4m   \
      --java-opt -Xms100m   \
      --java-opt -Dmetals.client=emacs \
      ${dep-name} \
      -r bintray:scalacenter/releases \
      -r sonatype:snapshots \
      -o $out/bin/${name}

      patchShebangs $out/bin/${name}
      wrapProgram $out/bin/${name} --prefix PATH ":" ${jre}/bin
    '';
  };

  drv = sbtixLib.buildSbtProgram {
    name = "weir";
    src = pkgs.nix-gitignore.gitignoreSource [] ./.;
    repo = [ (import ./manual-repo.nix)
             (import ./repo.nix)
             (import ./project/repo.nix)
           ];
  };

  shell = mkShell {
    buildInputs = [ sbt coursier metals-emacs sbtix ];
  };

  image = pkgs.dockerTools.buildLayeredImage {
    inherit name;
    tag = "latest";
    config.Cmd = [ "${drv}/bin/${name}"];
  };

in drv // { inherit shell image; }
