let
  nixpkgs = builtins.fetchTarball {
    name = "nixpkgs-unstable-szczyp-2021-07-21";
    url = "https://github.com/Szczyp/nixpkgs/archive/d354defbcb2cb7662adeaebb3fb4718a8a96bfd5.tar.gz";
    sha256 = "1i1jcvck17hj4awyl0xvq8jjn8vz3b0znxknkxffbiq791i0cb23";
  };
in
import nixpkgs {
  overlays = [
  ];
}
