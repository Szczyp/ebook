let
  nixpkgs = builtins.fetchTarball {
    name = "nixpkgs-unstable-small-szczyp-2019-12-13";
    url = "https://github.com/Szczyp/nixpkgs/archive/c8967467cad523cb861df6e07e939030cfd2c558.tar.gz";
    sha256 = "00gx95d093197zb1w2mb0pq83pd5gwglwq5mxam9n7frxxnnj0x9";
  };
  poetry2nix = builtins.fetchTarball {
    url = "https://github.com/adisbladis/poetry2nix/archive/84f27ee31de2d03f525cc80a3675642ecb4377ee.tar.gz";
    sha256 = "0gn4k7s7zdb4a19086b1faxnvqq34knra39r60c10nirlcjag179";
  };
in
import nixpkgs {
  overlays = [
    (import (poetry2nix + "/overlay.nix"))
  ];
}
