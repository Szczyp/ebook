#!/usr/bin/env python3

import email
import json
import os
from email import policy

from confluent_kafka import Consumer, Producer
from urlextract import URLExtract


def extract_links(msg):
    mail = email.message_from_bytes(msg.value(), policy=policy.default)
    sender = URLExtract(extract_email=True).find_urls(mail["From"])[0]
    payload = mail.get_payload(decode=True)
    urls = URLExtract().find_urls(str(payload))
    url = None if not urls else urls[0].rstrip("\\r\\n")
    return {"url": url, "from": sender}


def main():
    servers = os.environ.get("KAFKA_BOOTSTRAP_SERVERS") or "localhost:9092"

    producer = Producer({"bootstrap.servers": servers})

    consumer = Consumer(
        {
            "bootstrap.servers": servers,
            "group.id": "urex",
            "auto.offset.reset": "earliest",
        }
    )

    consumer.subscribe(["cartographer"])

    while True:
        msg = consumer.poll(1.0)

        if msg is None:
            continue

        links = extract_links(msg)

        if links["url"]:
            producer.produce(
                "urex", key=msg.key(), value=json.dumps(links).encode("utf8")
            )


if __name__ == "__main__":
    main()
