{ pkgs ? import ./nixpkgs.nix }:
with pkgs;

let
  overrides = [
    poetry2nix.defaultPoetryOverrides
    (self: super: {
      confluent-kafka = super.confluent-kafka.overrideAttrs(old: {
        buildInputs = old.buildInputs ++ [ pkgs.rdkafka ];
        dontStrip = false;
      });
    })
  ];

  drv = poetry2nix.mkPoetryApplication {
    src = lib.cleanSource ./.;
    pyproject = ./pyproject.toml;
    poetrylock = ./poetry.lock;
    python = python3;
    overrides = overrides;
  };

  env = poetry2nix.mkPoetryEnv {
    poetrylock = ./poetry.lock;
    python = python3;
    overrides = overrides;
  };

  shell = mkShell {
    buildInputs = [ env mailsend-go calibre ];
  };
in
drv // { inherit shell; }
