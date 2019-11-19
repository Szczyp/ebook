{ pkgs ? import <nixpkgs> {} }:

let
  python = import ./requirements.nix { inherit pkgs; };

  pypi2nix = pkgs.pythonPackages.callPackage(pkgs.fetchFromGitHub {
    owner  = "nix-community";
    repo   = "pypi2nix";
    rev    = "bdb7420ce6650be80957ec9be10480e6eacacd27";
    sha256 = "0jnxp76j4i4pjyqsyrzzb54nlhx6mqf7rhcix61pv1ghiq1l7lv2";
  }) {};

  name = "test-kafka-client";
  version = "1.0.0";

  drv = python.mkDerivation {
    name = "${name}-${version}";
    src = ./.;
    buildInputs = [];
    propagatedBuildInputs = (builtins.attrValues python.packages) ++ [ pkgs.mailsend-go ];
  };

  shell = pkgs.mkShell {
    buildInputs = [ python.interpreter pypi2nix pkgs.calibre pkgs.mailsend-go ];
  };

  image = pkgs.dockerTools.buildLayeredImage {
    inherit name;
    tag = "latest";
    config.Cmd = [ "${drv}/bin/${name}"];
  };
in
drv // { inherit shell image; }
