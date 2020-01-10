{ pkgs ? import ./nixpkgs.nix }:
with pkgs;

let
  overrides = [
    poetry2nix.defaultPoetryOverrides
    (self: super: {
      confluent-kafka = super.confluent-kafka.overrideAttrs(old: {
        buildInputs = old.buildInputs ++ [ rdkafka ];
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
    propagatedBuildInputs = [ kindlegen ];
  };

  env = poetry2nix.mkPoetryEnv {
    poetrylock = ./poetry.lock;
    python = python3;
    overrides = overrides;
  };

  shell = mkShell {
    buildInputs = [ env poetry poetry2nix.cli kindlegen ];
  };

  name = "mob";

  image = dockerTools.buildLayeredImage {
    inherit name;
    tag = "latest";
    config.Cmd = [ "${drv}/bin/${name}"];
  };
in
drv // { inherit shell image; }
