{ pkgs ? import <nixpkgs> {} }:
with pkgs;
with lib;
with builtins;
let
  mkPkg = path: callPackage path { inherit pkgs; };

  projects = [
    ./cartographer
    ./urex
    ./dog
    ./lit
    ./pubes
  ];

  packages = listToAttrs (map (path: { name = "${baseNameOf path}"; value = mkPkg path; }) projects);
  images = mapAttrs (n: p: p.image) packages;

in {
  inherit packages images;
}
