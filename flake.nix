{
  inputs = {
      nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
      readabilitySrc = {
        type = "github";
        owner = "Szczyp";
        repo = "readability";
        ref = "v1.0.3";
        flake = false;
      };
  };

  outputs = {self, nixpkgs, readabilitySrc}:
    let
      supportedSystems = [ "x86_64-linux" ]; #"x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgs = forAllSystems (system: nixpkgs.legacyPackages.${system});
      readability = system: pkgs.${system}.callPackage readabilitySrc {};
      deps = system: with pkgs.${system}; [ (readability system) pandoc imagemagick7 ];
    in rec {
      packages = forAllSystems (system: {
        default = pkgs.${system}.poetry2nix.mkPoetryApplication {
          projectDir = self;
          preferWheels = true;
          propagatedBuildInputs = (deps system);
        };
      });

      defaultPackage = forAllSystems (system: packages.${system}.default);

      devShells = forAllSystems (system: {
        default = pkgs.${system}.mkShellNoCC {
          packages = with pkgs.${system}; ([
            (poetry2nix.mkPoetryEnv {
              projectDir = self;
              preferWheels = true;
            })
            poetry
          ] ++ (deps system));
        };
      });
    };
}
