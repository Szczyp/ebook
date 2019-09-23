package cartographer;

import java.util.UUID;

import javax.inject.Singleton;

import io.micronaut.context.ApplicationContext;
import io.micronaut.core.naming.Described;
import io.micronaut.runtime.ApplicationConfiguration;
import io.micronaut.runtime.EmbeddedApplication;

@Singleton
public class ReceivedMailProducerApplication implements EmbeddedApplication<ReceivedMailProducerApplication>, Described {

    private final ApplicationContext context;
    private final ApplicationConfiguration configuration;
    private final MailStream mailStream;
    private final ReceivedMailProducer producer;

    private boolean isRunning = false;

    public ReceivedMailProducerApplication(ApplicationContext context, ApplicationConfiguration configuration,
            MailStream mailStream, ReceivedMailProducer producer) {
        this.context = context;
        this.configuration = configuration;
        this.mailStream = mailStream;
        this.producer = producer;
    }

    @Override
    public boolean isRunning() {
        return isRunning;
    }

    @Override
    public String getDescription() {
        return "waiting for emails.";
    }

    @Override
    public ApplicationConfiguration getApplicationConfiguration() {
        return configuration;
    }

    @Override
    public ApplicationContext getApplicationContext() {
        return context;
    }

    @Override
    public ReceivedMailProducerApplication start() {
        isRunning = true;
        mailStream.getMails().subscribe(mail -> {
            producer.send(UUID.randomUUID().toString(), mail);
        });
        return this;
    }

    @Override
    public ReceivedMailProducerApplication stop() {
        isRunning = false;
        return this;
    }
}