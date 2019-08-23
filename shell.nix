{ pkgs ? import <nixpkgs> {} }:
with pkgs;
let ebook = import ./requirements.nix {};
in
mkShell {
  buildInputs = [
    ebook.interpreter
    pandoc
    kindlegen
    readability
    calibre
  ];
}
