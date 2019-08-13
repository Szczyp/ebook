#!/usr/bin/env python3

import asyncio
import subprocess
import ssl
from time import sleep
import email
from email import policy
from imapclient import IMAPClient
from urlextract import URLExtract
from smtplib import SMTP
import mimetypes
import yaml

def read_config():
    with open('mailwatch.config.yaml', 'rb') as f:
        return yaml.safe_load(f)

CONFIG = read_config()
SSL_CONTEXT = ssl.create_default_context()

def fetch_mails():
    with IMAPClient(CONFIG['HOST'], ssl_context=SSL_CONTEXT) as imap:
        imap.login(CONFIG['USERNAME'], CONFIG['PASSWORD'])
        imap.select_folder('INBOX')
        messages = imap.search('UNSEEN')
        for uid, message_data in imap.fetch(messages, 'RFC822').items():
            yield email.message_from_bytes(message_data[b'RFC822'], policy=policy.default)

def extract_links(mails):
    for mail in mails:
        sender = URLExtract(extract_email=True).find_urls(mail["From"])[0]
        if sender in CONFIG['RECIPIENTS']:
            payload = mail.get_payload(decode=True)
            urls = URLExtract().find_urls(str(payload))
            url = urls[0].rstrip("\\r\\n")
            yield {'url': url, 'from': sender}

async def make_ebooks(bags):
    return await asyncio.gather(*[make_ebook(bag) for bag in bags])

async def make_ebook(bag):
    proc = await asyncio.subprocess.create_subprocess_exec('./make-ebook.sh', bag['url'], stdout=asyncio.subprocess.PIPE)
    name = await proc.stdout.readline()
    bag['ebook'] = name.decode('utf-8').replace("\n", '')
    await proc.wait()
    return bag

def create_mails(bags):
    for bag in bags:
        mail = email.message.EmailMessage()
        mail['From'] = CONFIG['USERNAME']
        mail["To"] = CONFIG['RECIPIENTS'][bag['from']]
        mail["Subject"] = bag['ebook']
        mail["Message-ID"] = email.utils.make_msgid()
        filename = f"out/{bag['ebook']}.mobi"
        with open(filename, 'rb') as f:
            mail.add_attachment(f.read(), filename=filename, maintype='application', subtype='octet-stream')
        yield mail

def send_mails(mails):
    mails = list(mails)
    if mails:
        with SMTP(CONFIG['HOST']) as smtp:
            smtp.starttls()
            smtp.login(CONFIG['USERNAME'], CONFIG['PASSWORD'])
            for mail in mails:
                smtp.send_message(mail)

def clear_workspace():
    subprocess.call('rm out/*', shell=True, stderr=subprocess.DEVNULL)

if __name__ == "__main__":
    while True:
        send_mails(
            create_mails(
                asyncio.run(
                    make_ebooks(
                        extract_links(
                            fetch_mails())))))
        clear_workspace()
        sleep(CONFIG['POLL_FREQUENCY'])
