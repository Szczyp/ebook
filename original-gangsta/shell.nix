{ pkgs ? import <nixpkgs> {} }:
(pkgs.pythonPackages.callPackage(./.){}).dev-env
