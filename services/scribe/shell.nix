{ pkgs ? import ../../nixpkgs.nix }:
(pkgs.callPackage(./.){}).shell
