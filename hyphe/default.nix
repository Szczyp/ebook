{ pkgs ? import <nixpkgs> {} }:
let
  name = "hyphe";

  src = pkgs.nix-gitignore.gitignoreSource [] ./.;

  haskellPackages = pkgs.haskell.packages.ghc865.override {
    overrides = self: super: {
      ${name} = self.callCabal2nix name src {};
    };
  };

  drv = pkgs.haskell.lib.justStaticExecutables haskellPackages.${name};

  shell = haskellPackages.shellFor {
    withHoogle = true;
    packages = p: [ p.${name} ];
    buildInputs = with haskellPackages; [
      apply-refact
      hindent
      hlint
      stylish-haskell
      hasktags
      hoogle
      (import (builtins.fetchTarball "https://github.com/hercules-ci/ghcide-nix/tarball/master") {}).ghcide-ghc865
    ];
  };

  image = pkgs.dockerTools.buildLayeredImage {
    inherit name;
    tag = "latest";
    config.Cmd = [ "${drv}/bin/${name}"];
  };
in
drv // { inherit shell image; }
