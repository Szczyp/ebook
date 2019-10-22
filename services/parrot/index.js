#!/usr/bin/env node

const HTMLParser = require("node-html-parser");
const Kafka = require("node-rdkafka");
const franc = require("franc");
const process = require("process");

const broker = process.env.KAFKA_BOOTSTRAP_SERVERS || "localhost:9092";

const consumer = Kafka.KafkaConsumer.createReadStream({
  "group.id": "parrot",
  "metadata.broker.list": broker
}, {}, {
  topics: ["lit"]
});

const producer = Kafka.Producer.createWriteStream({
  "metadata.broker.list": broker
}, {}, {
  topic: "parrot"
});

consumer.on("data", function(message) {
  const request = JSON.parse(message.value);
  const content = HTMLParser.parse(request.content);
  const lang = franc(content.text)
  request.lang = lang;
  let resp = JSON.stringify(request);
  producer.write(Buffer.from(resp));
});

consumer.on("error", function(err) {
  console.error(err);
});

producer.on("error", function(err) {
  console.error(err);
});
