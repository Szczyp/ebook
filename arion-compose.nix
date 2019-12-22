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
        "${toString ./.}/data/zoo/data:/data"
        "${toString ./.}/data/zoo/datalog:/datalog"
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
        "${toString ./.}/data/kafka/data:/var/lib/kafka/data"
      ];
    };

    cartographer.service = {
      useHostStore = true;
      command = [ "${packages.cartographer}/bin/cartographer" ];
      environment = {
        KAFKA_BOOTSTRAP_SERVERS = "kafka:19092";
        MICRONAUT_CONFIG_FILES = "/etc/cartographer/mail.yml";
      };
      volumes = [
        "${toString ./.}/configs/cartographer:/etc/cartographer"
      ];
    };

    urex.service = {
      useHostStore = true;
      command = [ "${packages.urex}/bin/urex" ];
      environment = {
        KAFKA_BOOTSTRAP_SERVERS = "kafka:19092";
      };
    };

    weir.service = {
      useHostStore = true;
      command = [ "${packages.weir}/bin/weir" ];
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

    lit.service = {
      useHostStore = true;
      command = [ "${packages.lit}/bin/lit" ];
      environment = {
        KAFKA_BOOTSTRAP_SERVERS = "kafka:19092";
      };
      restart = "always";
    };

    parrot.service  = {
      useHostStore = true;
      command = [ "${packages.parrot}/bin/parrot" ];
      environment = {
        KAFKA_BOOTSTRAP_SERVERS = "kafka:19092";
      };
      restart = "always";
    };

    hyphe.service = {
      useHostStore = true;
      command = [ "${packages.hyphe}/bin/hyphe" ];
      environment = {
        KAFKA_BOOTSTRAP_SERVERS = "kafka:19092";
      };
    };

    pubes.service = {
      useHostStore = true;
      command = [ "${packages.pubes}/bin/pubes" ];
      environment = {
        KAFKA_BOOTSTRAP_SERVERS = "kafka:19092";
      };
    };

    mob.service = {
      useHostStore = true;
      command = [ "${packages.mob}/bin/mob" ];
      tmpfs = [ "/tmp" ];
      environment = {
        KAFKA_BOOTSTRAP_SERVERS = "kafka:19092";
      };
    };

    scribe.service = {
      useHostStore = true;
      command = [ "${packages.scribe}/bin/scribe" ];
      tmpfs = [ "/tmp" ];
      environment = {
        KAFKA_BOOTSTRAP_SERVERS = "kafka:19092";
      };
      volumes = [
        "${toString ./.}/configs/scribe:/etc/scribe"
      ];
    };

    heave = {
      service = {
        image = "heave:latest";
        tmpfs = [ "/tmp" ];
        environment = {
          KAFKA_BOOTSTRAP_SERVERS = "kafka:19092";
        };
        volumes = [
          "${toString ./.}/configs/heave:/etc/heave"
        ];
      };
    };
  };
}
