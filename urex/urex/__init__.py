#!/usr/bin/env python3

from kafka import KafkaConsumer, KafkaProducer
import email
from email import policy
from urlextract import URLExtract
import json
import os


def extract_links(msg):
    mail = email.message_from_bytes(msg.value, policy=policy.default)
    sender = URLExtract(extract_email=True).find_urls(mail["From"])[0]
    payload = mail.get_payload(decode=True)
    urls = URLExtract().find_urls(str(payload))
    url = None if not urls else urls[0].rstrip("\\r\\n")
    return {'url': url, 'from': sender}


def main():
    servers = os.environ.get('KAFKA_BOOTSTRAP_SERVERS') or "localhost:9092"
    consumer = KafkaConsumer('received-mails', bootstrap_servers=servers)
    producer = KafkaProducer(value_serializer=lambda v: json.dumps(v).encode('utf8'),
                             bootstrap_servers=servers)

    for msg in consumer:
        links = extract_links(msg)
        if links['url']:
            producer.send('extracted-links', key=msg.key, value=links)


if __name__ == "__main__":
    main()
