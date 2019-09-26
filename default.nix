{ pkgs ? import <nixpkgs> {} }:
with pkgs;
let
  cartographer = callPackage ./cartographer { inherit pkgs; };
  cartographer-img = dockerTools.buildImage {
    name = "cartographer";
    tag = "latest";
    config.Cmd = [ "${cartographer}/bin/cartographer" ];
  };

  urex = callPackage ./urex { inherit pkgs; };
  urex-img = dockerTools.buildImage {
    name = "urex";
    tag = "latest";
    config.Cmd = [ "${urex}/bin/urex" ];
  };

  dog = callPackage ./dog { inherit pkgs; };
  dog-img = dockerTools.buildImage {
    name = "dog";
    tag = "latest";
    config.Cmd = [ "${dog}/bin/dog" ];
  };
in {
  inherit cartographer cartographer-img urex urex-img dog dog-img;
}
