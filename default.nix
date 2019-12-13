{ pkgs ? import ./nixpkgs.nix }:

let
  python = import ./requirements.nix { inherit pkgs; };

  external-dependencies = (with pkgs; [
    pandoc
    kindlegen
    readability
    imagemagick7
  ]);

  drv = python.mkDerivation {
    name = "ebook-1.0.4";
    src = ./.;
    buildInputs = [];
    propagatedBuildInputs = (builtins.attrValues python.packages) ++ external-dependencies;
  };

  dev-env = pkgs.mkShell {
    buildInputs = [ python.interpreter ] ++ external-dependencies;
  };
in
drv // { inherit dev-env; }
