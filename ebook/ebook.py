#!/usr/bin/env python3

import json
import argparse
import os
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
import aiohttp
import tempfile
import logging

logging.basicConfig(level = logging.INFO)

def read_config():
    global CONFIG
    argparser = argparse.ArgumentParser()
    argparser.add_argument('config')
    args = argparser.parse_args()
    with open(args.config, 'rb') as f:
        CONFIG = yaml.safe_load(f)

def fetch_mails():
    ssl_context = ssl.create_default_context()
    with IMAPClient(CONFIG['HOST'], ssl_context=ssl_context) as imap:
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
    headers = {'User-Agent': 'curl/7.65.3'}
    async with aiohttp.ClientSession(headers = headers) as session:
      return await asyncio.gather(*[make_ebook(session, bag) for bag in bags])

async def fetch_link(session, url):
    async with session.get(url) as response:
        return await response.text()

async def readability(html):
    proc = await asyncio.subprocess.create_subprocess_exec('readability',
                                                           stdin=asyncio.subprocess.PIPE,
                                                           stdout=asyncio.subprocess.PIPE)
    out, err = await proc.communicate(html.encode())
    return json.loads(out.decode())

async def make_epub(filename, title, author, content):
    os.chdir(os.path.dirname(__file__))
    proc = await asyncio.subprocess.create_subprocess_exec('pandoc',
		                                           '-s',
		                                           '--filter', 'hyphenate',
		                                           '--filter', 'strip_img',
		                                           '--section-divs',
		                                           '--toc-depth', '1',
		                                           '-o', f'{filename}.epub',
                                                           '-c', 'ebook.css',
                                                           '--template', 'template.t',
                                                           '-f', 'html',
		                                           '-t', 'epub3',
                                                           '--metadata', f'title={title}',
                                                           '--metadata', f'author={author}',
                                                           stdin=asyncio.subprocess.PIPE,
                                                           stdout=asyncio.subprocess.PIPE)
    await proc.communicate(content.encode())

async def make_mobi(filename):
    proc = await asyncio.subprocess.create_subprocess_exec('kindlegen',
                                                           f'{filename}.epub',
                                                           stdout=asyncio.subprocess.DEVNULL)
    await proc.wait()

async def make_ebook(session, bag):
    html = await fetch_link(session, bag['url'])
    article = await readability(html)
    name = article['title'] + (" - " + article['byline'] if article['byline'] else "")
    tmpdir = tempfile.mkdtemp()
    filename = os.path.join(tmpdir, name)
    await make_epub(filename, article['title'], article['byline'], article['content'])
    await make_mobi(filename)
    bag['name'] = name
    bag['filename'] = filename
    return bag

def create_mails(bags):
    for bag in bags:
        mail = email.message.EmailMessage()
        mail['From'] = CONFIG['USERNAME']
        mail["To"] = CONFIG['RECIPIENTS'][bag['from']]
        mail["Subject"] = os.path.basename(bag['name'])
        mail["Message-ID"] = email.utils.make_msgid()
        filename = bag['filename'] + ".mobi"
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
                logging.info("ebook sent from %s to %s: %s", mail['From'], mail['To'], mail['Subject'])

def main():
    read_config()
    URLExtract().update_when_older(30)
    send_mails(
        create_mails(
            asyncio.run(make_ebooks(
                extract_links(
                    fetch_mails())))))

if __name__ == "__main__":
    main()
