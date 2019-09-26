package main

import (
	"os"
	"net/http"
	"io/ioutil"
	"encoding/json"
	"gopkg.in/confluentinc/confluent-kafka-go.v1/kafka"
)

type Fetch struct {
	source string
	target string
}

type Release struct {
	target string
}

type extracted_links struct {
	Url string
	From string
}

type fetched_html struct {
	Url string
	From string
	Html string
}

func fetch(link string) string {
	resp, _ := http.Get(link)
	defer resp.Body.Close()
	body, _ := ioutil.ReadAll(resp.Body)
	return string(body)
}

func main() {
	servers := os.Getenv("KAFKA_BOOTSTRAP_SERVERS")
	if servers == "" {
		servers = "localhost:9092"
	}

	consumer, _ := kafka.NewConsumer(&kafka.ConfigMap{
		"bootstrap.servers": servers,
		"group.id":          "pack",
	})

	producer, _ := kafka.NewProducer(&kafka.ConfigMap{
		"bootstrap.servers": servers,
	})

	consumer.Subscribe( "extracted-links", nil)

	for {
		msg, _ := consumer.ReadMessage(-1)
		links := extracted_links{}
		json.Unmarshal(msg.Value, &links)
		h := fetch(links.Url)
		html := &fetched_html{
			Url: links.Url,
			From: links.From,
			Html: h}
		json, _ := json.Marshal(html)

		topic := "fetched_html"
		producer.Produce(&kafka.Message{
			TopicPartition: kafka.TopicPartition{Topic: &topic, Partition: kafka.PartitionAny},
			Key: msg.Key,
			Value: json,
		}, nil)
	}

	consumer.Close()
}
