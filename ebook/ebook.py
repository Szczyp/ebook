#!/usr/bin/env python3

import aiohttp
import argparse
import asyncio
from bs4 import BeautifulSoup
import email
from email import policy
from imapclient import IMAPClient
import json
import logging
import os
import re
import shutil
from smtplib import SMTP
import ssl
import tempfile
from urlextract import URLExtract
from urllib.parse import urlparse, urljoin
import yaml

logging.basicConfig(level=logging.INFO)


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
            yield email.message_from_bytes(message_data[b'RFC822'],
                                           policy=policy.default)


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
    async with aiohttp.ClientSession(headers=headers) as session:
        return await asyncio.gather(
            *[make_ebook(session, bag) for bag in bags])


async def fetch_link(session, url):
    async with session.get(url) as response:
        return await response.text()


async def fetch_img(session, url, filename):
    async with session.get(url) as response:
        with open(filename, 'wb') as f:
            async for chunk, _ in response.content.iter_chunks():
                f.write(chunk)


async def readability(html):
    proc = await asyncio.subprocess.create_subprocess_exec(
        'readability',
        stdin=asyncio.subprocess.PIPE,
        stdout=asyncio.subprocess.PIPE)
    out, err = await proc.communicate(html.encode())
    await proc.wait()
    return json.loads(out.decode())


async def make_epub(filename, title, author, content):
    os.chdir(os.path.dirname(__file__))
    proc = await asyncio.subprocess.create_subprocess_exec(
        'pandoc',
        '-s',
        '--filter', 'hyphenate',
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
    proc = await asyncio.subprocess.create_subprocess_exec(
        'kindlegen', f'{filename}.epub',
        stdout=asyncio.subprocess.DEVNULL)
    await proc.wait()


async def mogrify(filename):
    proc = await asyncio.subprocess.create_subprocess_exec(
        'mogrify',
        '-colorspace', 'Gray',
        '-alpha', 'off',
        '-quality', '85',
        '-strip',
        '-resize', '1072x1448>',
        filename)
    await proc.wait()

def get_name(article):
    return re.sub(
        ' {2,}', ' ',
        re.sub('[\t\r\n]', ' ',
               (article['title'] +
                (" - " + article['byline'] if article['byline'] else ""))))


async def convert_image(session, url, img, tmpdir):
    url = urljoin(url, img["src"])
    filename = os.path.join(tmpdir, os.path.basename(urlparse(url).path))
    await fetch_img(session, url, filename)
    await mogrify(filename)
    img["src"] = filename


async def convert_images(session, url, article, tmpdir):
    soup = BeautifulSoup(article["content"], "html.parser")
    await asyncio.gather(*[convert_image(session, url, img, tmpdir) for img in soup.find_all('img')])
    article["content"] = str(soup)


async def make_ebook(session, bag):
    url = bag['url']
    html = await fetch_link(session, url)
    article = await readability(html)
    tmpdir = tempfile.mkdtemp()
    await convert_images(session, url, article, tmpdir)
    name = get_name(article)
    filename = os.path.join(tmpdir, re.sub(r'(?u)[^-\w.]', ' ', name))
    await make_epub(filename, article['title'], article['byline'],
                    article['content'])
    await make_mobi(filename)
    bag['name'] = name
    bag['filename'] = filename
    return bag


def create_mails(bags):
    for bag in bags:
        mail = email.message.EmailMessage()
        mail['From'] = CONFIG['USERNAME']
        mail["To"] = CONFIG['RECIPIENTS'][bag['from']]
        mail["Subject"] = bag['name']
        mail["Message-ID"] = email.utils.make_msgid()
        filename = bag['filename'] + ".mobi"
        with open(filename, 'rb') as f:
            mail.add_attachment(f.read(),
                                filename=filename,
                                maintype='application',
                                subtype='octet-stream')
        yield mail


def send_mails(mails):
    mails = list(mails)
    if mails:
        with SMTP(CONFIG['HOST']) as smtp:
            smtp.starttls()
            smtp.login(CONFIG['USERNAME'], CONFIG['PASSWORD'])
            for mail in mails:
                smtp.send_message(mail)
                logging.info("ebook sent from %s to %s: %s", mail['From'],
                             mail['To'], mail['Subject'])


def main():
    read_config()
    URLExtract().update_when_older(30)
    send_mails(
        create_mails(
            asyncio.run(make_ebooks(
                extract_links(
                    fetch_mails())))))


def url2ebook():
    argparser = argparse.ArgumentParser()
    argparser.add_argument('url')
    args = argparser.parse_args()
    outpath = os.getcwd()
    bags = asyncio.run(make_ebooks([{'url': args.url}]))
    shutil.copy2(bags[0]['filename'] + ".epub", outpath)
    shutil.copy2(bags[0]['filename'] + ".mobi", outpath)


if __name__ == "__main__":
    main()
