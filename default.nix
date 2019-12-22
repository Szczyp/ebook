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
    "/heave"
  ];

  k8sConfig =
    let config = kubenix.evalModules {
          modules = [( import ./kubenix.nix { inherit kubenix pkgs projects; })];
        };
    in
      kubenix.lib.toYAML (kubenix.lib.k8s.mkHashedList { items = config.config.kubernetes.objects; });

  create-cluster-with-registry = writeShellScriptBin "create-cluster-with-registry" ''
    # desired cluster name; default is "kind"
    KIND_CLUSTER_NAME="''${KIND_CLUSTER_NAME:-kind}"

    # create registry container unless it already exists
    reg_name='kind-registry'
    reg_port='5000'
    running="$(${docker}/bin/docker inspect -f '{{.State.Running}}' "''${reg_name}")"
    if [ "''${running}" != 'true' ]; then
      ${docker}/bin/docker run \
        -d --restart=always -p "''${reg_port}:5000" --name "''${reg_name}" \
        registry:2
    fi

    # create a cluster with the local registry enabled in containerd
    cat <<EOF | ${kind}/bin/kind create cluster --config=-
    kind: Cluster
    apiVersion: kind.x-k8s.io/v1alpha4
    containerdConfigPatches:
    - |-
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry:''${reg_port}"]
        endpoint = ["http://registry:''${reg_port}"]
    EOF

    # add the registry to /etc/hosts on each node
    ip_fmt='{{.NetworkSettings.IPAddress}}'
    cmd="echo $(docker inspect -f "''${ip_fmt}" "''${reg_name}") registry >> /etc/hosts"
    for node in $(kind get nodes --name "''${KIND_CLUSTER_NAME}"); do
      ${docker}/bin/docker exec "''${node}" sh -c "''${cmd}"
    done
  '';

  build-images = writeShellScriptBin "build-images" ''
    set -euo pipefail

    for i in ${concatStringsSep " " (attrValues images)}
    do
      ${docker}/bin/docker load -i $i
    done

    for p in pubes scribe heave
    do
      pushd services/$p
      ${docker}/bin/docker build -t registry:5000/$p:latest .
      popd
    done

    for i in ${concatStringsSep " " (attrNames packages)}
    do
      ${docker}/bin/docker tag $i:latest registry:5000/$i:latest
      ${docker}/bin/docker push registry:5000/$i:latest
    done
  '';

  apply-config = writeShellScriptBin "apply-config" ''
    set -euo pipefail

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
    buildInputs = [ kind kubectl kafkacat create-cluster-with-registry build-images apply-config ];
  };

in {
  inherit packages images shell k8shell k8sConfig;
}
