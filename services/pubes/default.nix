{ pkgs ? import <nixpkgs> {} }:
let
  name = "pubes";

  src = pkgs.nix-gitignore.gitignoreSource [] ./.;

  haskellPackages = with pkgs.haskell; packages.ghc865.override {
    overrides = self: super: {
      ${name} = lib.overrideCabal (self.callCabal2nix name src {}) (drv: {
        postInstall = ''
          cp -r data $out/bin
        '';
      });
      hw-kafka-client = lib.dontCheck (self.callHackage "hw-kafka-client" "2.6.1" {});
    };
  };

  drv = pkgs.haskell.lib.justStaticExecutables haskellPackages.${name};

  shell = haskellPackages.shellFor {
    withHoogle = true;
    packages = p: [ p.${name} ];
    buildInputs = with haskellPackages; [
      cabal-install
      apply-refact
      hindent
      hlint
      stylish-haskell
      hasktags
      hoogle
      cabal2nix
      (import (builtins.fetchTarball "https://github.com/hercules-ci/ghcide-nix/tarball/master") {}).ghcide-ghc865
    ];
  };
in
drv // { inherit shell; }
