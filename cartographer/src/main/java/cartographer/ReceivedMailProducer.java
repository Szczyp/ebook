package cartographer;

import io.micronaut.configuration.kafka.annotation.KafkaClient;
import io.micronaut.configuration.kafka.annotation.KafkaKey;
import io.micronaut.configuration.kafka.annotation.Topic;
import io.micronaut.messaging.annotation.Body;

@KafkaClient("received-mail-producer")
public interface ReceivedMailProducer {
    @Topic("received-mails")
    void send(@KafkaKey String uuid, @Body byte[] mail);
}

