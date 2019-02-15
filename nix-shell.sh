#!/usr/bin/env bash
nix-shell -p pkgs.imagemagick 'pkgs.python3.withPackages (pkgs: with pkgs; [pandocfilters pyphen])' --command 'export PATH=$PATH:/home/qb/Downloads/kindlegen; return'
