FROM nixos/nix:2.3 AS base

RUN nix-channel --update

FROM base AS build

WORKDIR /opt/pubes

COPY pubes.cabal default.nix .gitignore /opt/pubes/

RUN nix-build -A buildEnv

COPY *.hs /opt/pubes/

COPY data /opt/pubes/data

RUN nix-build

FROM base

RUN nix-env -iA nixpkgs.gmp nixpkgs.rdkafka nixpkgs.zlib nixpkgs.lua5_3 nixpkgs.libffi

COPY --from=build /opt/pubes/result/bin /opt/pubes

ENTRYPOINT [ "/opt/pubes/pubes" ]