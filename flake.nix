{
  inputs = {
      nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
      utils.url = "github:numtide/flake-utils";
      readabilitySrc = {
        type = "github";
        owner = "Szczyp";
        repo = "readability";
        ref = "v1.0.3";
        flake = false;
      };
  };

  outputs = {self, nixpkgs, utils, readabilitySrc}:
    let out = system:
      let pkgs = nixpkgs.legacyPackages."${system}";
          readability = pkgs.callPackage readabilitySrc {};
          deps = with pkgs; [ readability pandoc imagemagick7 ];
      in {

          devShell = with pkgs; (poetry2nix.mkPoetryEnv {
            projectDir = ./.;
            preferWheels = true;
          }).env.overrideAttrs (_: {
            buildInputs = [ poetry ] ++ deps;
          });

          defaultPackage = with pkgs.poetry2nix; mkPoetryApplication {
              projectDir = ./.;
              preferWheels = true;
              propagatedBuildInputs = deps;
          };

          defaultApp = utils.lib.mkApp {
              drv = self.defaultPackage."${system}";
          };

      }; in with utils.lib; eachSystem defaultSystems out;

}
