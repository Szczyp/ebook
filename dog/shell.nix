{ pkgs ? import <nixpkgs> {} }:
(pkgs.callPackage(./.){}).shell
