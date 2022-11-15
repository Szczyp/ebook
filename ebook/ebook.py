#!/usr/bin/env python3

import argparse
import asyncio
import email
import json
import logging
import os
import re
import shutil
import ssl
import tempfile
from email import policy
from pathlib import Path
from smtplib import SMTP
from urllib.parse import urljoin, urlparse

import aiohttp
import yaml
from bs4 import BeautifulSoup
from imapclient import IMAPClient
from langdetect import detect
from urlextract import URLExtract

logging.basicConfig(level=logging.INFO)
logging.getLogger('filelock').setLevel(logging.WARNING)
logger = logging.getLogger(__name__)

def read_config():
    global CONFIG
    argparser = argparse.ArgumentParser()
    argparser.add_argument('--config', default = f"{Path.home()}/.config/ebook/config.yml")
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
    def strip_newlines(url):
        newlines = "\\r\\n"
        return url.lstrip(newlines).rstrip(newlines)

    for mail in mails:
        sender = URLExtract(extract_email=True).find_urls(mail["From"])[0]
        if sender in CONFIG['RECIPIENTS']:
            for part in mail.walk():
                if part.get_content_maintype() == "text":
                    for url in URLExtract().find_urls(part.get_content()):
                        yield {'url': strip_newlines(url), 'from': sender}
                    break


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


languages = {
    "en": "en-US",
    "pl": "pl-PL"
}

def detect_language(article):
    return languages[detect(article)]


async def make_epub(filename, lang, title, author, content):
    os.chdir(os.path.dirname(__file__))
    proc = await asyncio.subprocess.create_subprocess_exec(
        'pandoc',
        '--metadata', f'title={title}',
        '--metadata', f'author={author}',
        '--metadata', f'language={lang}',
        '-s',
        '--filter', 'hyphenate',
        '--section-divs',
        '--toc-depth', '1',
        '-o', f'{filename}.epub',
        '-c', 'ebook.css',
        '--template', 'template.t',
        '-f', 'html',
        '-t', 'epub3',
        stdin=asyncio.subprocess.PIPE,
        stdout=asyncio.subprocess.PIPE)
    await proc.communicate(content.encode())


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
    if "src" in img and img["src"]:
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
    lang = detect_language(article['content'])
    tmpdir = tempfile.mkdtemp()
    await convert_images(session, url, article, tmpdir)
    name = get_name(article)
    filename = os.path.join(tmpdir, re.sub(r'(?u)[^-\w.]', ' ', name))
    await make_epub(filename, lang, article['title'], article['byline'],
                    article['content'])
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
        filename = bag['filename'] + ".epub"
        name = os.path.basename(filename)
        with open(filename, 'rb') as f:
            mail.add_attachment(f.read(),
                                filename=name,
                                maintype='application',
                                subtype='octet-stream')
        yield mail


def send_mails(mails):
    mails = list(mails)
    if mails:
        with SMTP(CONFIG['HOST'], 587) as smtp:
            smtp.starttls()
            smtp.login(CONFIG['USERNAME'], CONFIG['PASSWORD'])
            for mail in mails:
                smtp.send_message(mail)
                logger.info("ebook sent from %s to %s: %s", mail['From'],
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


if __name__ == "__main__":
    main()
