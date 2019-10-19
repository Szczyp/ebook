package main

import (
	"os"
	"net/http"
	"io/ioutil"
	"encoding/json"
	"gopkg.in/confluentinc/confluent-kafka-go.v1/kafka"
)

type urex struct {
	Url string
	From string
}

type dog struct {
	Url string `json:"url"`
	From string `json:"from"`
	Html string `json:"html"`
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
		"group.id":          "dog",
	})

	producer, _ := kafka.NewProducer(&kafka.ConfigMap{
		"bootstrap.servers": servers,
	})

	consumer.Subscribe("urex", nil)

	for {
		msg, _ := consumer.ReadMessage(-1)
		if msg != nil {
			links := urex{}
			json.Unmarshal(msg.Value, &links)
			h := fetch(links.Url)
			html := &dog{
				Url: links.Url,
				From: links.From,
				Html: h}
			json, _ := json.Marshal(html)

			topic := "dog"
			producer.Produce(&kafka.Message{
				TopicPartition: kafka.TopicPartition{Topic: &topic, Partition: kafka.PartitionAny},
				Key: msg.Key,
				Value: json,
			}, nil)
		}
	}

	consumer.Close()
}
