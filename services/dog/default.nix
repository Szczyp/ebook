{ pkgs ? import ./nixpkgs.nix }:
with pkgs;
let
  name = "dog";
  version = "1.0.0";

  drv = buildGoModule {
    name = "${name}-${version}";
    version = version;
    src = pkgs.nix-gitignore.gitignoreSource [] ./.;
    buildInputs = [ rdkafka pkg-config ];
    modSha256 = "0ny06w9ksnfb4b7nvlczlyff21g1h06h7bmhxhh4y722q8vjki21";

    subPackages = [ "." ];
  };

  image = dockerTools.buildLayeredImage {
    name = name;
    tag = "latest";
    contents = [ cacert ];
    config.Cmd = [ "${drv}/bin/${name}"];
  };

  shell = pkgs.mkShell {
    buildInputs = [ go govers dep gocode godef goimports gogetdoc gopkgs impl pkg-config vgo2nix rdkafka ];
    shellHook = ''
      unset GOPATH
    '';
  };
in
drv // { inherit shell image; }
