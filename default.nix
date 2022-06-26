{ pkgs ? import <nixpkgs> { } }:

with pkgs;

let
  readability = callPackage (
    fetchTarball {
      url = https://github.com/Szczyp/readability/archive/refs/tags/v1.0.3.tar.gz;
      sha256 = "06mfabsnkw0l44ynfbk7yyh9g6s4ys0q4g64y0xkiy0a8h6859h4";
    }) { };

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

  external-dependencies = [
    pandoc-bin
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

  image = dockerTools.buildImage {
    name = "ebook";
    contents = external-dependencies ++ [ cacert drv ];
    config = {
      Env = [ "SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt" ];
      Cmd = [ "ebook" "config" ];
    };
  };
in
drv // { inherit shell image; }
