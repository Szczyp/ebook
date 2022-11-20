{
  inputs = {
      nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
      readability.url = "github:Szczyp/readability";
  };

  outputs = {self, nixpkgs, readability}:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgs = forAllSystems (system: nixpkgs.legacyPackages.${system});
      deps = system: with pkgs.${system}; [
        readability.packages.${system}.default
        pandoc
        imagemagick7
      ];
    in rec {
      packages = forAllSystems (system: {
        default = pkgs.${system}.poetry2nix.mkPoetryApplication {
          projectDir = self;
          preferWheels = true;
          propagatedBuildInputs = (deps system);
        };
      });

      overlays.default = (final: prev: rec {
        ebook = packages.${final.system}.default;
      });

      nixosModules.default = import ./module.nix;

      devShells = forAllSystems (system: {
        default = pkgs.${system}.mkShellNoCC {
          packages = with pkgs.${system}; ([
            (poetry2nix.mkPoetryEnv {
              projectDir = self;
              preferWheels = true;
            })
            poetry
            nodePackages.pyright
          ] ++ (deps system));
        };
      });
    };
}
