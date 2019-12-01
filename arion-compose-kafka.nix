{ pkgs, ... }:
let
  services = (import ./arion-compose.nix { inherit pkgs; }).config.services;
in
{
  config.services = {
    inherit (services) zoo kafka;
  };
}
