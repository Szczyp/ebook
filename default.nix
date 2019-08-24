{ pkgs ? import <nixpkgs> {} }:

let
  python = import ./requirements.nix { inherit pkgs; };
in python.mkDerivation {
  name = "ebook-1.0.2";
  src = ./.;
  buildInputs = [];
  propagatedBuildInputs =
    (builtins.attrValues python.packages)
    ++ (with pkgs; [
      pandoc
      kindlegen
      readability
    ]);
}
