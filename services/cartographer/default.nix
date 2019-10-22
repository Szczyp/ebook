# This file has been generated by mavenix-2.3.0. Configure the build here!
let
  mavenix-src = fetchTarball { url = "https://github.com/icetan/mavenix/tarball/v2.3.0"; sha256 = "10jyfrc2s45ylff3bw9abvsanrn0xcci8v07b5jn7ibx4y8cwi4c"; };
in {
  pkgs ? import <nixpkgs> {},
  mavenix ? import mavenix-src { inherit pkgs; },
  doCheck ? false,
}:
  let
    name = "cartographer";
    version = "1.0.0";

    drv = mavenix.buildMaven {
      inherit doCheck;

      name = "${name}-${version}";

      infoFile = ./mavenix.lock;

      src = ./.;

      # Add build dependencies
      #
      buildInputs = with pkgs; [ makeWrapper ];

      # Set build environment variables
      #
      #MAVEN_OPTS = "-Dfile.encoding=UTF-8";

      # Attributes are passed to the underlying `stdenv.mkDerivation`, so build
      #   hooks can be set here also.
      #
      postInstall = ''
   makeWrapper ${pkgs.jdk12_headless}/bin/java $out/bin/cartographer \
     --add-flags "-jar $out/share/java/cartographer-0.1.jar"
  '';

      # Add extra maven dependencies which might not have been picked up
      #   automatically
      #
      #deps = [
      #  { path = "org/group-id/artifactId/version/file.jar"; sha1 = "0123456789abcdef"; }
      #  { path = "org/group-id/artifactId/version/file.pom"; sha1 = "123456789abcdef0"; }
      #];

      # Add dependencies on other mavenix derivations
      #
      #drvs = [ (import ../other/mavenix/derivation {}) ];

      # Override which maven package to build with
      #
      maven = pkgs.maven.overrideAttrs (_: { jdk = pkgs.jdk12_headless; });

      # Override remote repository URLs and settings.xml
      #
      #remotes = { central = "https://repo.maven.apache.org/maven2"; };
      #settings = ./settings.xml;
    };

    image = pkgs.dockerTools.buildLayeredImage {
      inherit name;
      tag = "latest";
      config.Cmd = [ "${drv}/bin/${name}"];
    };

  in drv // { inherit image; }