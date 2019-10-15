from confluent_kafka import Consumer, Producer
import json

def main():
    consumer = Consumer({
        'bootstrap.servers': "localhost:9092",
        'group.id': 'test-client',
        'auto.offset.reset': 'earliest'
    })

    consumer.subscribe(['epub'])

    while True:
        msg = consumer.poll(1.0)

        if msg is None:
            continue

        j = json.loads(msg.value())

        print(j["epub"])


if __name__ == "__main__":
    main()
