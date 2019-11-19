{ pkgs, kubenix, projects }:
with pkgs;
with lib;
let
  mkDeployment = {name, env ? [], tempdir ? false}:
    {
      metadata = {
        name = name;
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
              env = [{ name = "KAFKA_BOOTSTRAP_SERVERS"; value = "bootstrap.kafka:9092"; }] ++ env;
              resources.limits.cpu = "100m";
              volumeMounts = if tempdir then [{ name = "tempdir"; mountPath = "/tmp"; }] else [];
            };
            volumes = if tempdir then [{ name = "tempdir"; emptyDir = {}; }] else [];
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
          "cartographer" = { env = [{ name = "MICRONAUT_CONFIG_FILES"; value = "classpath:mail.yml"; }]; };
          "mob" = { tempdir = true; };
        }
      ]);

  topics = map createTopic projectNames;
in
{
  imports = with kubenix.modules; [ k8s ];

  kubernetes.resources.jobs."create-ebook-topics" = {
    metadata = {
      name = "create-ebook-topics";
      namespace = "ebook";
    };
    spec.template.spec = {
      restartPolicy = "Never";
      containers = topics;
    };
  };

  kubernetes.resources.deployments = deployments;
}
