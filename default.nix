{ pkgs ? import <nixpkgs> {} }:

let
  python = import ./requirements.nix { inherit pkgs; };

  external-dependencies = (with pkgs; [
    pandoc
    kindlegen
    readability
  ]);

  drv = python.mkDerivation {
    name = "ebook-1.0.3";
    src = ./.;
    buildInputs = [];
    propagatedBuildInputs = (builtins.attrValues python.packages) ++ external-dependencies;
  };

  dev-env = pkgs.mkShell {
    buildInputs = [ python.interpreter ] ++ external-dependencies;
  };
in
if pkgs.lib.inNixShell then dev-env else drv
