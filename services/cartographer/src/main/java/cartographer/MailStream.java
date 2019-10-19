package cartographer;

import reactor.core.publisher.Flux;

public interface MailStream {
    Flux<byte[]> getMails();
}