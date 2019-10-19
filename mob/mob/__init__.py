#!/usr/bin/env python3

import base64
import json
import os
import re
import subprocess
import tempfile

from confluent_kafka import Consumer, Producer


def main():
    servers = os.environ.get("KAFKA_BOOTSTRAP_SERVERS") or "localhost:9092"

    producer = Producer({"bootstrap.servers": servers})

    consumer = Consumer(
        {
            "bootstrap.servers": servers,
            "group.id": "mob",
            "auto.offset.reset": "earliest",
        }
    )

    consumer.subscribe(["pubes"])

    while True:
        msg = consumer.poll(1.0)

        if msg is None:
            continue

        pubes = json.loads(msg.value())
        epub = base64.b64decode(pubes["epub"])

        with tempfile.TemporaryDirectory() as tmpdir:
            base_filename = os.path.join(
                tmpdir, re.sub(r"(?u)[^-\w.]", " ", pubes["title"])
            )
            filename_epub = f"{base_filename}.epub"
            filename_mobi = f"{base_filename}.mobi"

            with open(filename_epub, "wb") as f:
                f.write(epub)

            subprocess.run(["kindlegen", filename_epub])

            with open(filename_mobi, "rb") as f:
                pubes["mobi"] = base64.b64encode(f.read()).decode("utf8")

        producer.produce(
            "mob", key=msg.key(), value=json.dumps(pubes).encode("utf8")
        )


if __name__ == "__main__":
    main()
