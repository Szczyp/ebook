#!/usr/bin/env python3

import json
import sys

import confluent_kafka


consumer = confluent_kafka.Consumer(
    {
        "bootstrap.servers": "localhost:9092",
        "group.id": "test-client",
        "auto.offset.reset": "earliest",
    }
)


def pipe():
    consumer.subscribe(
        ["cartographer", "urex", "dog", "lit", "parrot", "hyphe", "pubes", "mob"]
    )

    while True:
        msg = consumer.poll(1.0)

        if msg is None:
            continue

        print(msg.topic())


def out(topic):
    consumer.subscribe([topic])

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
