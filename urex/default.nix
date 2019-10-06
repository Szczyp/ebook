{ pkgs ? import <nixpkgs> {} }:

let
  python = import ./requirements.nix { inherit pkgs; };

  name = "urex";
  version = "1.0.0";

  drv = python.mkDerivation {
    name = "${name}-${version}";
    src = ./.;
    buildInputs = [];
    propagatedBuildInputs = (builtins.attrValues python.packages);
  };

  shell = pkgs.mkShell {
    buildInputs = [ python.interpreter ];
  };

  image = pkgs.dockerTools.buildLayeredImage {
    inherit name;
    tag = "latest";
    config.Cmd = [ "${drv}/bin/${name}"];
  };
in
drv // { inherit shell image; }
