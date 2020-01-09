{ pkgs, kubenix, projects }:
with pkgs;
with lib;
with builtins;
let
  configs = attrNames (readDir ./configs);

  mkSecret = name:
    {
      type = "Opaque";
      stringData = mapAttrs
        (f: _: readFile (./configs + "/${name}/${f}"))
        (readDir (./configs + "/${name}"));
    };

  mkDeployment = { name, env ? {}, tmp ? false }:
    let
      emptyVolumes = { mounts = []; volumes = []; };

      tempVolumes = if tmp
                    then {
                      mounts = [{ name = "tmp"; mountPath = "/tmp"; }];
                      volumes = [{ name = "tmp"; emptyDir = {}; }];
                    } else emptyVolumes;

      configVolumes = if elem name configs
                      then {
                        mounts = [{ name = "config"; mountPath = "/etc/${name}"; readOnly = true; }];
                        volumes = [{ name = "config"; secret = { secretName = name; }; }];
                      } else emptyVolumes;

      finalVolumes = zipAttrsWith (_: v: concatLists v) [ tempVolumes configVolumes ];

      defaultEnv = { KAFKA_BOOTSTRAP_SERVERS = "kafka:9092"; };

      finalEnv = mapAttrsToList nameValuePair (defaultEnv // env);

    in
      {
        metadata = {
          labels = {
            app = name;
          };
        };

        spec = {
          replicas = 1;
          selector.matchLabels.app = name;
          template = {
            metadata.labels.app = name;
            spec = {
              containers."${name}" = {
                image = "registry.local/${name}:latest";
                imagePullPolicy = "Always";
                env = finalEnv;
                resources.limits.cpu = "100m";
                volumeMounts = finalVolumes.mounts;
              };
              volumes = finalVolumes.volumes;
            };
          };
        };
      };

  mkStatefulSet = name: { image, env ? [], ports ? [], resources ? {}, persistentVolumes }:
    let
      claim = name: { storage, ... }: {
        metadata.name = name;
        spec = {
          accessModes = [ "ReadWriteOnce" ];
          resources.requests.storage = storage;
          storageClassName = "standard";
        };
      };
      mount = name: { mountPath, ... }: {
        inherit name mountPath;
      };
    in {
      spec = {
        podManagementPolicy = "Parallel";
        updateStrategy.type = "RollingUpdate";
        replicas = 1;
        selector.matchLabels.app = name;
        serviceName = name;
        template = {
          metadata.labels.app = name;
          spec = {
            containers."${name}" = {
              image = image;
              env = mapAttrsToList nameValuePair env;
              ports = mapAttrsToList (n: p: { name = n; containerPort = p; }) ports;
              resources = resources;
              volumeMounts = mapAttrsToList mount persistentVolumes;
            };
            terminationGracePeriodSeconds = 30;
          };
        };
        volumeClaimTemplates = mapAttrsToList claim persistentVolumes;
      };
    };

  projectNames = map (path: baseNameOf path) projects;

  mkDeployments = deployments: mapAttrs (n: v: mkDeployment v)
    (zipAttrsWith (n: vs: foldr (a: b: a // b) {} vs)
      [
        (genAttrs projectNames (name: {inherit name;}))
        deployments
      ]);

  mkService = name: attrs: {
    spec = {
      ports = mapAttrsToList (n: p: { name = n; port = p; }) attrs.ports;
      selector.app = name;
    };
  };
in
{
  imports = with kubenix.modules; [ k8s ];

  kubernetes.resources = {
    secrets = listToAttrs (map (c: nameValuePair c (mkSecret c)) configs);

    services = mapAttrs mkService {
      kafka = { ports = { kafka = 9092; }; };
      zookeeper =  { ports = { client = 2181; peer = 2888; election = 3888; }; };
    };

    statefulSets = mapAttrs mkStatefulSet {
      kafka = {
        image = "wurstmeister/kafka:2.12-2.3.1";
        env = {
          KAFKA_ADVERTISED_HOST_NAME = "kafka";
          KAFKA_PORT = "9092";
          KAFKA_ZOOKEEPER_CONNECT = "zookeeper:2181";
          KAFKA_HEAP_OPTS = "-Xms256M -Xmx256M";
        };
        ports = { kafka = 9092; };
        resources = {
          limits.memory = "600Mi";
          requests = {
            cpu = "100m";
            memory = "100Mi";
          };
        };
        persistentVolumes = {
          data = {
            mountPath = "/var/lib/kafka/data";
            storage = "10Gi";
          };
        };
      };

      zookeeper = {
        image = "zookeeper:3.4.9";
        env = {
          ZOO_MY_ID = "1";
          ZOO_PORT = "2181";
          ZOO_SERVERS = "server.1=zookeeper:2888:3888";
        };
        ports = { client = 2181; peer = 2888; election = 3888; };
        resources = {
          limits.memory = "120Mi";
          requests = {
            cpu = "10m";
            memory = "100Mi";
          };
        };
        persistentVolumes = {
          data = {
            mountPath = "/var/lib/zookeeper";
            storage = "1Gi";
          };
        };
      };
    };

    deployments = mkDeployments {
      cartographer = { env = { MICRONAUT_CONFIG_FILES = "/etc/cartographer/mail.yml"; }; };
      mob = { tmp = true; };
      scribe = { tmp = true; };
      heave = { tmp = true; };
    };
  };
}
