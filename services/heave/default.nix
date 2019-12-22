{ pkgs ? import ./nixpkgs.nix }:
with pkgs;
let
  name = "heave";
  version = "1.0.0";

  dotnet2nix = callPackage (fetchFromGitHub {
    owner  = "Szczyp";
    repo   = "dotnet2nix";
    rev    = "a2b0515398ad1c12ea6a0f57599a1a591ba2b163";
    sha256 = "13z7x4ljlndvm1khy8m0yc358phwf7ja7gnnba9c5kzv1dg8sk89";
  }) {};

  drv = dotnet2nix.mkDotNetCoreProject {
    project = name;
    version = version;
    config = "Release";
    src = pkgs.nix-gitignore.gitignoreSource [] ./.;
    meta = {};
  };

  shell = pkgs.mkShell {
    buildInputs = [ dotnet-sdk vscode omnisharp-roslyn dotnet2nix.cli ];
  };
in
drv // { inherit shell; }
