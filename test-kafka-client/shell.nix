{ pkgs ? import <nixpkgs> {} }:
(pkgs.pythonPackages.callPackage(./.){}).shell
