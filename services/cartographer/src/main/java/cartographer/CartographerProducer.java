package cartographer;

import io.micronaut.configuration.kafka.annotation.KafkaClient;
import io.micronaut.configuration.kafka.annotation.KafkaKey;
import io.micronaut.configuration.kafka.annotation.Topic;
import io.micronaut.messaging.annotation.Body;

@KafkaClient("cartographer")
public interface CartographerProducer {
    @Topic("cartographer")
    void send(@KafkaKey String uuid, @Body byte[] mail);
}

