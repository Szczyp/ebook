import subprocess
import ssl
from time import sleep
import email
from email import policy
from imapclient import IMAPClient
from urlextract import URLExtract
from smtplib import SMTP
import mimetypes

HOST = '***REMOVED***'
USERNAME = '***REMOVED***'
PASSWORD = '***REMOVED***'

RECIPIENTS = {'qb@szczyp.com': 'wrzut@kindle.com'}

ssl_context = ssl.create_default_context()

def fetch_links():
    with IMAPClient(HOST, ssl_context=ssl_context) as imap:
        imap.login(USERNAME, PASSWORD)
        imap.select_folder('INBOX')
        messages = imap.search('UNSEEN')
        for uid, message_data in imap.fetch(messages, 'RFC822').items():
            mail = email.message_from_bytes(message_data[b'RFC822'], policy=policy.default)
            if mail['From'] in RECIPIENTS:
                payload = mail.get_payload(decode=True)
                extractor = URLExtract()
                urls = extractor.find_urls(str(payload))
                url = urls[0].rstrip("\\r\\n")
                yield {'url': url, 'from': mail['From']}

def make_ebooks(bags):
    for bag in bags:
        name = subprocess.check_output(['./make-ebook.sh', bag['url']])
        bag['ebook'] = name.decode('utf-8').replace("\n", '')
        yield bag

def create_mails(bags):
    for bag in bags:
        mail = email.message.EmailMessage()
        mail['From'] = USERNAME
        mail["To"] = RECIPIENTS[bag['from']]
        mail["Subject"] = bag['ebook']
        mail["Message-ID"] = email.utils.make_msgid()
        filename = bag['ebook'] + ".mobi"
        with open(filename, 'rb') as f:
            mail.add_attachment(f.read(), filename=filename, maintype='application', subtype='octet-stream')
        yield mail

def send_mails(mails):
    with SMTP(HOST) as smtp:
        smtp.starttls()
        smtp.login(USERNAME, PASSWORD)
        for mail in mails:
            smtp.send_message(mail)

def remove_sent_ebooks():
    subprocess.call('rm *.mobi', shell=True, stderr=subprocess.DEVNULL)

while True:
    send_mails(create_mails(make_ebooks(fetch_links())))
    remove_sent_ebooks()
    sleep(60)

