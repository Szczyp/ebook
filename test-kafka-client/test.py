#!/usr/bin/env python3
import sys
from confluent_kafka import Consumer, Producer
import json

def pipe():
    consumer = Consumer({
        'bootstrap.servers': "localhost:9092",
        'group.id': 'test-client',
        'auto.offset.reset': 'earliest'
    })

    consumer.subscribe(
        ['cartographer',
         'urex',
         'dog',
         'lit',
         'parrot',
         'hyphe',
         'pubes'])

    while True:
        msg = consumer.poll(1.0)

        if msg is None:
            continue

        print(msg.topic())


def out():
    consumer = Consumer({
        'bootstrap.servers': "localhost:9092",
        'group.id': 'test-client',
        'auto.offset.reset': 'earliest'
    })

    consumer.subscribe(['pubes'])

    while True:
        msg = consumer.poll(1.0)

        if msg is None:
            continue

        print(json.dumps(json.loads(msg.value())))


def main():
    if len(sys.argv) > 1:
        cmd = sys.argv[1]
        if cmd == "pipe":
            pipe()
        elif cmd == "out":
            out()
        else:
            print("unknown cmd")

if __name__ == "__main__":
    main()
