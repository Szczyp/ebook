{ pkgs, kubenix, projects }:
with pkgs;
with lib;
with builtins;
let
  configs = attrNames (readDir ./configs);

  mkSecret = name:
    { metadata = {
        name = name;
        namespace = "ebook";
      };
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

      defaultEnv = { KAFKA_BOOTSTRAP_SERVERS = "bootstrap.kafka:9092"; };

      finalEnv = mapAttrsToList nameValuePair (defaultEnv // env);

    in
      {
        metadata = {
          name = name;
          namespace = "ebook";
          labels = {
            app = name;
            namespace = "ebook";
          };
        };

        spec = {
          replicas = 1;
          selector.matchLabels.app = name;
          template = {
            metadata.labels.app = name;
            spec = {
              containers."${name}" = {
                name = "${name}";
                image = "${name}:latest";
                imagePullPolicy = "IfNotPresent";
                env = finalEnv;
                resources.limits.cpu = "100m";
                volumeMounts = finalVolumes.mounts;
              };
              volumes = finalVolumes.volumes;
            };
          };
        };
      };

  createTopic = name: {
    name = "create-${name}-topic";
    image = "solsson/kafka-cli@sha256:9fa3306e9f5d18283d10e01f7c115d8321eedc682f262aff784bd0126e1f2221";
    command = [
      "./bin/kafka-topics.sh"
      "--zookeeper"
      "zookeeper.kafka:2181"
      "--create"
      "--if-not-exists"
      "--topic"
      "${name}"
      "--partitions"
      "1"
      "--replication-factor"
      "1"
    ];
    resources.limits = {
      cpu = "100m";
      memory = "20Mi";
    };
  };

  projectNames = map (path: baseNameOf path) projects;

  deployments = mapAttrs (n: v: mkDeployment v)
    (zipAttrsWith (n: vs: foldr (a: b: a // b) {} vs)
      [
        (genAttrs projectNames (name: {inherit name;}))
        {
          cartographer = { env = { MICRONAUT_CONFIG_FILES = "classpath:mail.yml"; }; };
          mob = { tmp = true; };
          scribe = { tmp = true; };
        }
      ]);

  topics = map createTopic (projectNames ++ [ "draft" ]);
in
{
  imports = with kubenix.modules; [ k8s ];

  kubernetes.resources = {
    jobs."create-ebook-topics" = {
      metadata = {
        name = "create-ebook-topics";
        namespace = "ebook";
      };
      spec.template.spec = {
        restartPolicy = "Never";
        containers = topics;
      };
    };

    secrets = listToAttrs (map (c: nameValuePair c (mkSecret c)) configs);

    deployments = deployments;
  };
}
