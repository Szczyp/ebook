{ pkgs ? import ./nixpkgs.nix }:
with pkgs;
let
  mavenix = (callPackage (fetchFromGitHub {
      owner  = "icetan";
      repo   = "mavenix";
      rev    = "v2.3.0";
      sha256 = "10jyfrc2s45ylff3bw9abvsanrn0xcci8v07b5jn7ibx4y8cwi4c";
    }) {}).cli;
in
mkShell {
  buildInputs = [ adoptopenjdk-bin maven mavenix ];
}
