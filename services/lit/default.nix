{ pkgs ? import ./nixpkgs.nix }:
let
  name = "lit";
  version = "1.0.0";

  nodejs = pkgs.nodejs-12_x;

  rdkafka = with pkgs; stdenv.mkDerivation rec {
    pname = "rdkafka";
    version = "1.2.2";

    src = fetchFromGitHub {
      owner = "edenhill";
      repo = "librdkafka";
      rev = "v${version}";
      sha256 = "1daikjr2wcjxcys41hfw3vg2mqk6cy297pfcl05s90wnjvd7fkqk";
    };

    nativeBuildInputs = [ pkgconfig ];
    buildInputs = [ zlib perl python openssl ];

    NIX_CFLAGS_COMPILE = "-Wno-error=strict-overflow";

    postPatch = ''
      patchShebangs .
    '';
  };

  pnpm2nix = import (pkgs.fetchFromGitHub {
    owner = "adisbladis";
    repo = "pnpm2nix";
    rev = "master";
    sha256 = "1ck4k4qlwrdvs22ar2hvcn26lj17i481prwa4a684nd344fi191z"; })
    { inherit pkgs nodejs; inherit (pkgs) nodePackages; };

  drv = pnpm2nix.mkPnpmPackage {
    src = pkgs.nix-gitignore.gitignoreSource [] ./.;
    overrides = pnpm2nix.defaultPnpmOverrides // {
      node-rdkafka = (drv: drv.overrideAttrs(oldAttrs: {
        LIBRDKAFKA=rdkafka;
      }));
    };
    allowImpure = true;
  };

  shell = pkgs.mkShell {
    buildInputs = [ nodejs ] ++ (with pkgs.nodePackages; [ pnpm typescript typescript-language-server ]);
    shellHook = ''
      export LIBRDKAFKA=${rdkafka}
    '';
  };

  image = pkgs.dockerTools.buildLayeredImage {
    inherit name;
    tag = "latest";
    config.Cmd = [ "${drv}/bin/${name}"];
  };
in
drv // { inherit shell image; }
