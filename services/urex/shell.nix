{ pkgs ? import ../../nixpkgs.nix }:
(pkgs.pythonPackages.callPackage(./.){}).shell
