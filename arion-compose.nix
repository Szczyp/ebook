{ pkgs, ... }:
let
  packages = (import ./. {}).packages;
in
{
  config.services = {
    zoo.service = {
      image = "zookeeper:3.4.9";
      hostname = "zoo";
      ports = [ "2181:2181" ];
      environment = {
        ZOO_MY_ID = "1";
        ZOO_PORT = "2181";
        ZOO_SERVERS = "server.1=zoo:2888:3888";
      };
      volumes = [
        "${toString ./.}/kafka/zoo/data:/data"
        "${toString ./.}/kafka/zoo/datalog:/datalog"
      ];
    };

    kafka.service = {
      image = "confluentinc/cp-kafka:5.3.1";
      hostname = "kafka";
      ports = [ "9092:9092" ];
      environment = {
        KAFKA_ADVERTISED_LISTENERS = "LISTENER_DOCKER_INTERNAL://kafka:19092,LISTENER_DOCKER_EXTERNAL://\${DOCKER_HOST_IP:-127.0.0.1}:9092";
        KAFKA_LISTENER_SECURITY_PROTOCOL_MAP = "LISTENER_DOCKER_INTERNAL:PLAINTEXT,LISTENER_DOCKER_EXTERNAL:PLAINTEXT";
        KAFKA_INTER_BROKER_LISTENER_NAME = "LISTENER_DOCKER_INTERNAL";
        KAFKA_ZOOKEEPER_CONNECT = "zoo:2181";
        KAFKA_BROKER_ID = "1";
        KAFKA_LOG4J_LOGGERS = "kafka.controller=INFO,kafka.producer.async.DefaultEventHandler=INFO,state.change.logger=INFO";
        KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR = "1";
        KAFKA_HEAP_OPTS = "-Xms256M -Xmx256M";
      };
      volumes = [
        "${toString ./.}/kafka/kafka/data:/var/lib/kafka/data"
      ];
    };

    cartographer.service = {
      useHostStore = true;
      command = [ "${packages.cartographer}/bin/cartographer" ];
      environment = {
        KAFKA_BOOTSTRAP_SERVERS = "kafka:19092";
        MICRONAUT_CONFIG_FILES = "classpath:mail.yml";
      };
    };

    urex.service = {
      useHostStore = true;
      command = [ "${packages.urex}/bin/urex" ];
      environment = {
        KAFKA_BOOTSTRAP_SERVERS = "kafka:19092";
      };
    };

    dog = {
      image = {
        contents = [ pkgs.cacert ];
        command = [ "${packages.dog}/bin/dog" ];
      };
      service.environment = {
        KAFKA_BOOTSTRAP_SERVERS = "kafka:19092";
      };
    };

    lit = {
      image = {
        command = [ "${packages.lit}/bin/lit" ];
      };
      service.environment = {
        KAFKA_BOOTSTRAP_SERVERS = "kafka:19092";
      };
    };

    parrot = {
      image = {
        command = [ "${packages.parrot}/bin/parrot" ];
      };
      service.environment = {
        KAFKA_BOOTSTRAP_SERVERS = "kafka:19092";
      };
    };

    hyphe.service = {
      useHostStore = true;
      command = [ "${packages.hyphe}/bin/hyphe" ];
      environment = {
        KAFKA_BOOTSTRAP_SERVERS = "kafka:19092";
      };
    };

    # pubes = {
    #   image = {
    #     command = [ "${packages.pubes}/bin/pubes" ];
    #   };
    #   service = {
    #     environment = {
    #       KAFKA_BOOTSTRAP_SERVERS = "kafka:19092";
    #     };
    #     volumes = [
    #       "${toString ./.}/pubes/data:/data:ro"
    #     ];
    #   };
    # };
  };
}
