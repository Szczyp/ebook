{ pkgs ? import <nixpkgs> {} }:
let
  name = "lit";
  version = "1.0.0";
  nodejs = pkgs.nodejs-10_x;
  nodeHeaders = pkgs.fetchurl {
    url = "https://nodejs.org/download/release/v${nodejs.version}/node-v${nodejs.version}-headers.tar.gz";
    sha256 = "0m2yp73rig154iazvs9d1zmi2k32lci5i76pz4idkxg0pzqx2089";
  };
  rdkafka = with pkgs; stdenv.mkDerivation rec {
    pname = "rdkafka";
    version = "1.1.0";

    src = fetchFromGitHub {
      owner = "edenhill";
      repo = "librdkafka";
      rev = "v${version}";
      sha256 = "03h4yxnbnig17zapnnyvvnh1bsp0qalvlpb4fc3bpvs7yj4d8v25";
    };

    nativeBuildInputs = [ pkgconfig ];
    buildInputs = [ zlib perl python openssl ];

    NIX_CFLAGS_COMPILE = "-Wno-error=strict-overflow";

    postPatch = ''
      patchShebangs .
    '';
  };
  yarn = pkgs.yarn.override { inherit nodejs; };
  yarn2nix = pkgs.callPackage (pkgs.fetchFromGitHub {
      owner  = "moretea";
      repo   = "yarn2nix";
      rev    = "7effadded30d611a460e212cb73614506ef61c52";
      sha256 = "0r4ww3mjx3n7bn2v1iav33liyphyr2x005ak6644qs15bp4bn3cr";
  }) { inherit pkgs nodejs yarn; };
  yarn-install = pkgs.writeScriptBin "yarn-install" ''
    #!/usr/bin/env bash
    export LIBRDKAFKA=${rdkafka}
    export npm_config_tarball=${nodeHeaders}
    yarn install --check-files
  '';
  drv = yarn2nix.mkYarnPackage {
    name = "${name}-${version}";
    src = pkgs.nix-gitignore.gitignoreSource [] ./.;
    packageJSON = ./package.json;
    yarnLock = ./yarn.lock;
    yarnNix = ./yarn.nix;
    pkgConfig = {
      node-rdkafka = {
        buildInputs = with pkgs; [ python binutils gcc gnumake nodePackages.node-gyp ];
        postInstall = ''
          export LIBRDKAFKA=${rdkafka}
          node-gyp rebuild --tarball=${nodeHeaders}
        '';
      };
    };
  };
  shell = pkgs.mkShell {
    buildInputs = with pkgs; [ python binutils gcc gnumake ] ++ [ nodejs yarn yarn2nix.yarn2nix yarn-install ];
  };
    image = pkgs.dockerTools.buildLayeredImage {
      inherit name;
      tag = "latest";
      config.Cmd = [ "${drv}/bin/${name}"];
    };
in
drv // { inherit shell image; }
