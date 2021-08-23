{ pkgs ? import ./nixpkgs.nix }:

with pkgs;

let
  readability = (callPackage (fetchFromGitHub {
    owner  = "Szczyp";
    repo   = "readability";
    rev    = "v1.0.1";
    sha256 = "0fd1r3j5kia26gkgzab2aqh52knl2qyqml24b25mg8yqcx51m7n0";
  }) { inherit pkgs; }).package;

  pandoc-bin = stdenv.mkDerivation {
    name = "pandoc-bin";
    propagatedBuildInputs = [ texlive.combined.scheme-basic ];
    src = fetchTarball {
      url = https://github.com/jgm/pandoc/releases/download/2.7.3/pandoc-2.7.3-linux.tar.gz;
      sha256 = "192wxd7519zd6whka6bqbhlgmkzmwszi8fgd39hfr8cz78bc8whc";
    };
    buildPhase = "true";
    installPhase = ''
    mkdir -p $out/bin
    cp bin/pandoc $out/bin
  '';
  };

  kindlegen = callPackage ./vendor/kindlegen.nix { };

  external-dependencies = [
    pandoc-bin
    kindlegen
    readability
    imagemagick7
  ];

  drv = poetry2nix.mkPoetryApplication {
    projectDir = ./.;
  };

  env = poetry2nix.mkPoetryEnv {
    projectDir = ./.;
  };

  shell = mkShell {
    buildInputs = [ env poetry ] ++ external-dependencies;
  };
in
drv // { inherit shell; }
