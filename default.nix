{ pkgs ? import ./nixpkgs.nix }:
with pkgs;
with lib;
with builtins;
let
  kubenix = callPackage (fetchFromGitHub {
    owner = "xtruder";
    repo = "kubenix";
    rev = "kubenix-2.0";
    sha256 = "1rmhwic80vlra5g1ism0q46jbmx52wmc34cxw3k9i6q5xbx291g1";
  }) { inherit pkgs; };

  mkPkg = path: import path {};

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
    "/heave"
  ];

  k8sConfig =
    let config = kubenix.evalModules {
          modules = [( import ./kubenix.nix { inherit kubenix pkgs projects; })];
        };
    in
      kubenix.lib.toYAML (kubenix.lib.k8s.mkHashedList { items = config.config.kubernetes.objects; });

  create-cluster = writeShellScriptBin "create-cluster" ''
    cat <<EOF | ${kind}/bin/kind create cluster --config=-
    kind: Cluster
    apiVersion: kind.x-k8s.io/v1alpha4
    containerdConfigPatches:
    - |-
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry.local"]
        endpoint = ["http://registry.local"]
    EOF

    cmd="echo $(grep registry.local /etc/hosts) >> /etc/hosts"
    for node in $(${kind}/bin/kind get nodes); do
      ${docker}/bin/docker exec "''${node}" sh -c "''${cmd}"
    done
  '';

  push-images = writeShellScriptBin "push-images" ''
    set -euo pipefail

    for i in ${concatStringsSep " " (attrValues images)}
    do
      ${docker}/bin/docker load -i $i
    done

    for p in pubes scribe heave
    do
      pushd services/$p
      ${docker}/bin/docker build -t $p:latest .
      popd
    done

    for i in ${concatStringsSep " " (attrNames packages)}
    do
      ${docker}/bin/docker tag $i:latest registry.local/$i:latest
      ${docker}/bin/docker push registry.local/$i:latest
    done
  '';

  packages = listToAttrs (map (path: { name = "${baseNameOf path}"; value = mkPkg path; }) projects);

  images = mapAttrs (n: v: v.image) (filterAttrs (n: v: v ? image) packages);

  shell = mkShell {
    buildInputs = [ arion kafkacat kind kubectl create-cluster push-images ];
  };

in {
  inherit packages images shell k8sConfig;
}
