{ pkgs ? import <nixpkgs> {} }:

let
  python = import ./requirements.nix { inherit pkgs; };

  drv = python.mkDerivation {
    name = "urex-1.0.0";
    src = ./.;
    buildInputs = [];
    propagatedBuildInputs = (builtins.attrValues python.packages);
  };

  shell = pkgs.mkShell {
    buildInputs = [ python.interpreter ];
  };
in
drv // { inherit shell; }
