let
  poetry2nix = import (builtins.fetchTarball {
     name = "poetry2nix";
     url = "https://github.com/nix-community/poetry2nix/archive/2f60530909a9726675f66509610f1f8c41b77cda.tar.gz";
     sha256 =  "078kzi544vahh8z84x0ay5fmaxblgmghzdy3iny23s600wmfymqv";
  } + "/overlay.nix");
  nixpkgs = builtins.fetchTarball {
    name = "szczyp-unstable-small";
    url = "https://github.com/Szczyp/nixpkgs/archive/6ca04d66276aa3a203109243742825507224c524.tar.gz";
    sha256 = "00imhrj3jw9hw446fqxxggrq4pvnvhswfrb1wphbr6dnnl73cql1";
  };
in
import nixpkgs { overlays = [ poetry2nix ]; }

