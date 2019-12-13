{ pkgs ? import ./nixpkgs.nix }:

with pkgs;

let
  readability = (callPackage (fetchFromGitHub {
    owner  = "Szczyp";
    repo   = "readability";
    rev    = "v1.0.0";
    sha256 = "0dbwcb2xsnp9qyx71pghk7p4s1x0zh38qn73h34sgqshwhx23py1";
  }) { inherit pkgs; }).package;

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
