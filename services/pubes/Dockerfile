FROM haskell:8.6.5 AS build

WORKDIR /opt/pubes

RUN echo "deb http://deb.debian.org/debian stretch-backports main contrib non-free" > /etc/apt/sources.list.d/stretch-backports.list

RUN apt-get update && apt-get -y install librdkafka-dev/stretch-backports c2hs

RUN cabal update

COPY pubes.cabal /opt/pubes/pubes.cabal

RUN cabal install --only-dependencies -j4

COPY *.hs /opt/pubes/

RUN cabal build

FROM debian:stretch-slim

RUN echo "deb http://deb.debian.org/debian stretch-backports main contrib non-free" > /etc/apt/sources.list.d/stretch-backports.list

RUN apt-get update && apt-get -y install librdkafka-dev/stretch-backports libgmp-dev libffi-dev libncurses-dev libtinfo5

COPY --from=build /opt/pubes/dist/build/pubes/pubes /opt/pubes/

COPY data /opt/pubes/data

ENTRYPOINT [ "/opt/pubes/pubes" ]