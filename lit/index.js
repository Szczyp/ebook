#!/usr/bin/env node

const Kafka = require("node-rdkafka");
const jsdom = require("jsdom");
const { JSDOM } = jsdom;
const Readability = require("readability");
const process = require("process");

const broker = process.env.KAFKA_BOOTSTRAP_SERVERS || "localhost:9092";

const consumer = Kafka.KafkaConsumer.createReadStream({
  "group.id": "lit",
  "metadata.broker.list": broker
}, {}, {
  topics: [ "fetched_html" ]
});

const producer = Kafka.Producer.createWriteStream({
  "metadata.broker.list": broker
}, {}, {
  topic: "articles"
});

consumer.on("data", function(message) {
  const request = JSON.parse(message.value);
  const doc = new JSDOM(request.html, {url: request.url});
  const reader = new Readability(doc.window.document);
  let article = reader.parse();

  let resp = JSON.stringify({...article, ...request});
  producer.write(Buffer.from(resp));
});

consumer.on("error", function(err) {
  console.error(err);
});

producer.on("error", function(err) {
  console.error(err);
});
