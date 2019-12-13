let
  nixpkgs = import ./nixpkgs.nix;

  poetry-overlay = import ((builtins.fetchTarball {
    url = https://github.com/adisbladis/poetry2nix/archive/master.tar.gz; }) + "/overlay.nix");
in
{ pkgs ? nixpkgs.extend poetry-overlay }:

with pkgs;

let
  external-dependencies = [
    pandoc
    kindlegen
    readability
    imagemagick7
  ];

  drv = (poetry2nix.mkPoetryPackage {
    python = python37;
    pyproject = ./pyproject.toml;
    poetryLock = ./poetry.lock;
    src = lib.cleanSource ./.;
  }).overrideAttrs (d: {
    propagatedBuildInputs = d.propagatedBuildInputs ++ external-dependencies;
  });

  shell = pkgs.mkShell {
    buildInputs = [ poetry ] ++ external-dependencies;
  };
in
drv // { inherit shell; }
