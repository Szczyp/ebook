{ pkgs ? import <nixpkgs> {} }:
with pkgs;
with lib;
with builtins;
let
  arion = (import (builtins.fetchTarball https://github.com/hercules-ci/arion/tarball/master) {}).arion;

  mkPkg = path: callPackage path { inherit pkgs; };

  projects = [
    ./cartographer
    ./urex
    ./dog
    ./lit
    ./parrot
    ./hyphe
    ./pubes
  ];

  packages = listToAttrs (map (path: { name = "${baseNameOf path}"; value = mkPkg path; }) projects);
  images = mapAttrs (n: p: p.image) packages;

  shell = mkShell {
    buildInputs = [ arion mailsend-go ];
  };
in {
  inherit packages images shell;
}
