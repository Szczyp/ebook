#!/usr/bin/env python3

import json
import os
import sys
import subprocess

import confluent_kafka

servers = os.environ.get("KAFKA_BOOTSTRAP_SERVERS") or "localhost:9092"

consumer = confluent_kafka.Consumer(
    {
        "bootstrap.servers": servers,
        "group.id": "test-client",
        "auto.offset.reset": "earliest",
    }
)


def send_test_mail():
    subprocess.Popen(["./send-test-mail.sh"])


def pipe():
    topics = ["cartographer", "urex", "dog", "lit", "parrot", "hyphe", "pubes", "mob"]
    consumer.subscribe(topics)
    results = []

    send_test_mail()

    while set(topics) != set(results):
        msg = consumer.poll(1.0)

        if msg is None:
            continue

        results.append(msg.topic())

    print("OK.")


def out(topic):
    consumer.subscribe([topic])

    send_test_mail()

    while True:
        msg = consumer.poll(1.0)

        if msg is None:
            continue

        print(json.dumps(json.loads(msg.value())))

        break


def main():
    if len(sys.argv) > 1:
        cmd = sys.argv[1]
        if cmd == "pipe":
            pipe()
        elif cmd == "out":
            if len(sys.argv) > 2:
                out(sys.argv[2])
            else:
                print("topic required")
        else:
            print("unknown cmd")


if __name__ == "__main__":
    main()
