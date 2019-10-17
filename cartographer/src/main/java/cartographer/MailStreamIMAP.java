package cartographer;

import java.io.ByteArrayOutputStream;
import java.util.Properties;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;

import javax.inject.Singleton;
import javax.mail.Folder;
import javax.mail.Message;
import javax.mail.Session;
import javax.mail.Store;
import javax.mail.event.MessageCountEvent;
import javax.mail.event.MessageCountListener;

import com.sun.mail.imap.IdleManager;

import io.micronaut.context.annotation.Property;
import reactor.core.publisher.Flux;

@Singleton
public class MailStreamIMAP implements MailStream {

    @Property(name = "mail.imap.host")
    protected String host;
    @Property(name = "mail.imap.user")
    protected String user;
    @Property(name = "mail.imap.password")
    protected String password;

    private Properties props = System.getProperties();

    private Executor executor = Executors.newCachedThreadPool();

    public MailStreamIMAP() {
        props.setProperty("mail.imaps.usesocketchannels", "true");
        props.setProperty("mail.event.scope", "application");
        props.put("mail.event.executor", executor);
    }

    @Override
    public Flux<byte[]> getMails() {
        Session session = Session.getDefaultInstance(props);
        return Flux.create(sink -> {
            try {
                final IdleManager idleManager = new IdleManager(session, executor);

                final Store store = session.getStore("imaps");
                store.connect(host, user, password);

                final Folder inbox = store.getFolder("INBOX");
                inbox.open(Folder.READ_ONLY);
                inbox.addMessageCountListener(new MessageCountListener() {

                    @Override
                    public void messagesRemoved(MessageCountEvent e) {
                    }

                    @Override
                    public void messagesAdded(MessageCountEvent e) {
                        try {
                            for (Message message : e.getMessages()) {
                                try(var out = new ByteArrayOutputStream()){
                                    message.writeTo(out);
                                    sink.next(out.toByteArray());
                                }
                            }
                            idleManager.watch(inbox);
                        } catch (Exception ex) {
                            ex.printStackTrace();
                            sink.error(ex);
                        }
                    }
                });
                idleManager.watch(inbox);
            } catch (Exception e) {
                e.printStackTrace();
                sink.error(e);
            }
        });
    }
}
