{ pkgs ? import <nixpkgs> {} }:
with pkgs;
let

  drv = buildGoModule {
    name = "dog-1.0.0";
    src = ./.;
    buildInputs = [ rdkafka pkg-config ];
    modSha256 = "0ny06w9ksnfb4b7nvlczlyff21g1h06h7bmhxhh4y722q8vjki21";

    subPackages = [ "." ];
  };

  shell = pkgs.mkShell {
    buildInputs = [ go govers dep gocode godef goimports gogetdoc gopkgs impl pkg-config vgo2nix rdkafka ];
    shellHook = ''
      unset GOPATH
    '';
  };
in
drv // { inherit shell; }
