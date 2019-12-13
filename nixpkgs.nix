import (builtins.fetchGit {
  name = "nixpkgs-unstable-small-szczyp-2019-12-13";
  url = "https://github.com/Szczyp/nixpkgs";
  ref = "unstable-small";
  rev = "c8967467cad523cb861df6e07e939030cfd2c558";
}) {
  overlays = [
    (import ((builtins.fetchTarball {
      url = https://github.com/adisbladis/poetry2nix/archive/master.tar.gz; }) + "/overlay.nix"))
  ];
}
