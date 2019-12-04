package main

import (
	"os"
	"net/http"
	"io/ioutil"
	"encoding/json"
	"gopkg.in/confluentinc/confluent-kafka-go.v1/kafka"
)

func fetch(link string) (string, error) {
	resp, err := http.Get(link)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	body, _ := ioutil.ReadAll(resp.Body)
	return string(body), nil
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

	consumer.Subscribe("weir", nil)

	for {
		msg, _ := consumer.ReadMessage(-1)
		if msg != nil {
			var data map[string]interface{}
			json.Unmarshal(msg.Value, &data)
			html, err := fetch(data["url"].(string))
			if err != nil {
				continue
			}
			data["html"] = html
			json, _ := json.Marshal(data)

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
