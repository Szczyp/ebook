{ pkgs ? import ./nixpkgs.nix }:
let
  name = "parrot";
  version = "1.0.0";

  nodejs = pkgs.nodejs-12_x;

  rdkafka = pkgs.rdkafka.overrideAttrs (old: rec {
    version = "1.2.2";
    src = builtins.fetchTarball {
      url = "https://github.com/edenhill/${old.pname}/archive/v${version}.tar.gz";
      sha256 = "1daikjr2wcjxcys41hfw3vg2mqk6cy297pfcl05s90wnjvd7fkqk";
    };
  });

  pnpm2nix = import (builtins.fetchTarball {
    url = "https://github.com/nix-community/pnpm2nix/archive/b7cb9d9569f0659862f4696fc29a7f7ca4061a75.tar.gz";
    sha256 = "1nk5mm8psjmq66ggj5flqb154d7yl4j3riy3cdx33yjjbvwvhqh7"; })
    { inherit pkgs nodejs; inherit (pkgs) nodePackages; };

  drv = pnpm2nix.mkPnpmPackage {
    src = pkgs.nix-gitignore.gitignoreSource [] ./.;
    allowImpure = true;
    overrides = pnpm2nix.defaultPnpmOverrides // {
      node-rdkafka = (drv: drv.overrideAttrs(old: {
        LIBRDKAFKA=rdkafka;
        postBuild = ''
          rm -r /build/node_modules/node-rdkafka/build/Release/obj.target
          strip /build/node_modules/node-rdkafka/build/Release/node-librdkafka.node
        '';
      }));
    };
  };

  env = pnpm2nix.mkPnpmEnv drv;

  shell = pkgs.mkShell {
    buildInputs = [ env ] ++ (with pkgs.nodePackages; [ pnpm typescript typescript-language-server ]);
  };

  image = pkgs.dockerTools.buildLayeredImage {
    inherit name;
    tag = "latest";
    config.Cmd = [ "${drv}/bin/${name}"];
  };
in
drv // { inherit shell image; }
