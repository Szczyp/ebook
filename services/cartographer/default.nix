{ pkgs ? import ./nixpkgs.nix }:

with pkgs;

let
  name = "cartographer";
  version = "1.0.0";

  mavenix = import (fetchTarball {
    url = "https://github.com/icetan/mavenix/tarball/v2.3.2";
    sha256 = "11c8120dm6c6gid2yyy7psbbvmvahjpjd32ly6xh2h0c4q1k2z48"; })
    { inherit pkgs; };

  drv = mavenix.buildMaven {
    name = "${name}-${version}";

    infoFile = ./mavenix.lock;

    src = nix-gitignore.gitignoreSource [] ./.;

    buildInputs = [ makeWrapper ];

    postInstall = ''
        makeWrapper ${adoptopenjdk-jre-bin}/bin/java $out/bin/${name} \
          --add-flags "-jar $out/share/java/${name}-${version}.jar"
      '';

    maven = maven.overrideAttrs (_: { jdk = adoptopenjdk-bin; });
  };

  shell = mkShell {
    buildInputs = [ adoptopenjdk-bin maven mavenix.cli ];
  };

  image = dockerTools.buildLayeredImage {
    inherit name;
    tag = "latest";
    config.Cmd = [ "${drv}/bin/${name}"];
  };

in drv // { inherit shell image; }
