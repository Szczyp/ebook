{ pkgs ? import ../../nixpkgs.nix }:

let
  python = import ./requirements.nix { inherit pkgs; };

  pypi2nix = pkgs.pythonPackages.callPackage(pkgs.fetchFromGitHub {
    owner  = "nix-community";
    repo   = "pypi2nix";
    rev    = "bdb7420ce6650be80957ec9be10480e6eacacd27";
    sha256 = "0jnxp76j4i4pjyqsyrzzb54nlhx6mqf7rhcix61pv1ghiq1l7lv2";
  }) {};

  readLines = file: with pkgs.lib; splitString "\n" (removeSuffix "\n" (builtins.readFile file));
  fromRequirementsFile = file: pythonPackages:
    builtins.map (name: builtins.getAttr name pythonPackages)
      (builtins.filter (l: l != "") (readLines file));

  name = "mob";
  version = "1.0.0";

  drv = python.mkDerivation {
    name = "${name}-${version}";
    src = ./.;
    buildInputs = [];
    propagatedBuildInputs = (fromRequirementsFile ./requirements.txt python.packages) ++ [ pkgs.kindlegen ];
  };

  shell = pkgs.mkShell {
    buildInputs = [ python.interpreter pypi2nix ];
  };

  image = pkgs.dockerTools.buildLayeredImage {
    inherit name;
    tag = "latest";
    config.Cmd = [ "${drv}/bin/${name}"];
  };
in
drv // { inherit shell image; }
