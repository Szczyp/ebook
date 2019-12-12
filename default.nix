{ pkgs ? import ./nixpkgs.nix }:
with pkgs;
with lib;
with builtins;
let
  arion = (import (builtins.fetchTarball https://github.com/hercules-ci/arion/tarball/master) {}).arion;

  kubenix = callPackage (fetchFromGitHub {
    owner = "xtruder";
    repo = "kubenix";
    rev = "kubenix-2.0";
    sha256 = "1rmhwic80vlra5g1ism0q46jbmx52wmc34cxw3k9i6q5xbx291g1";
  }) { inherit pkgs; };

  mkPkg = path: callPackage path {};

  projects = map (s: ./services + s) [
    "/cartographer"
    "/urex"
    "/weir"
    "/dog"
    "/lit"
    "/parrot"
    "/hyphe"
    "/pubes"
    "/mob"
    "/scribe"
  ];

  k8sConfig =
    let config = kubenix.evalModules {
          modules = [( import ./kubenix.nix { inherit kubenix pkgs projects; })];
        };
    in
      kubenix.lib.toYAML (kubenix.lib.k8s.mkHashedList { items = config.config.kubernetes.objects; });

  recreate-cluster = writeScriptBin "recreate-cluster" ''
      #! ${pkgs.runtimeShell}
      set -euo pipefail

      ${kind}/bin/kind delete cluster || true
      ${kind}/bin/kind create cluster

      export KUBECONFIG=$(${kind}/bin/kind get kubeconfig-path --name="kind")

      for i in ${concatStringsSep " " (attrValues images)}
      do
        echo "docker: loading image $i..."
        ${docker}/bin/docker load -i $i
      done

      pushd services/pubes
      ${docker}/bin/docker build -t pubes:latest .
      popd

      for i in ${concatStringsSep " " (attrNames packages)}
      do
        echo "kind: loading image $i:latest..."
        ${kind}/bin/kind load docker-image $i:latest
        echo "kind: loaded image $i:latest"
      done

      ${kubectl}/bin/kubectl create namespace kafka
      ${kubectl}/bin/kubectl apply -k ../kubernetes-kafka/variants/dev-small

      ${kubectl}/bin/kubectl create namespace ebook
      ${kubectl}/bin/kubectl apply -f ${k8sConfig}
  '';

  packages = listToAttrs (map (path: { name = "${baseNameOf path}"; value = mkPkg path; }) projects);
  images = mapAttrs (n: v: v.image) (filterAttrs (n: v: v ? image) packages);

  shell = mkShell {
    buildInputs = [ arion kafkacat ];
  };

  k8shell = mkShell {
    buildInputs = [ kind kubectl kafkacat recreate-cluster ];
    shellHook = ''
      source recreate-cluster
    '';
  };

in {
  inherit packages images shell k8shell k8sConfig;
}
