import re
import random
import urllib
import urllib.request

import plistlib

from os import listdir, makedirs
from os.path import join, exists

from time import sleep
from selenium import webdriver
from bs4 import BeautifulSoup

MAX_PAGE_TITLE_LENGTH = 25
ILLEGAL_PAGE_TITLE_ITEMS = [
    ":",
    "#",
    ",_",
    "List",
    "disambiguation",
    "(",
    "Outline"
]


def create_folders():
    directory = "/Users/andrewfinke/Desktop/WKRPython/"
    if not exists(directory):
        makedirs(directory)

    directory = "/Users/andrewfinke/Desktop/WKRPython/PageLinksTests/"
    if not exists(directory):
        makedirs(directory)

    directory = "/Users/andrewfinke/Desktop/WKRPython/NetworkTests/"
    if not exists(directory):
        makedirs(directory)


def is_valid_article(article):
    if len(article) > MAX_PAGE_TITLE_LENGTH:
        return False

    for illegal_item in ILLEGAL_PAGE_TITLE_ITEMS:
        if illegal_item in article:
            return False

    return True


def articles_properties(article):
    url = "https://en.m.wikipedia.org/wiki" + article
    try:
        html_page = urllib.request.urlopen(url)
        soup = BeautifulSoup(html_page)
        allrows = soup.findAll('th')
        userrows = [t for t in allrows if t.findAll(text=re.compile('Born'))]
        is_person_article = len(userrows) > 0

        dis_text = " page lists articles associated with the title "
        is_disambiguation_article = dis_text in str(soup)
    except:
        print("ERROR: " + article)
        return False, False
    return is_person_article, is_disambiguation_article


def remove_articles_with_year(articles):
    years = [str(i) for i in range(1000, 2100)]
    clean_articles = []
    for article in articles:
        is_clean = True
        for year in years:
            if year in article:
                is_clean = False
                break

        if is_clean:
            clean_articles.append(article)
    return clean_articles


def load_articles_in_directory(path):
    articles = []
    files = [join(path, f) for f in listdir(path)]

    for file in files:
        if "DS_Store" not in file:
            articles += plistlib.readPlist(file)
    return set(articles)


def word_count_in_strings(articles):
    words = {}
    for article in articles:
        for word in article[1:].replace("_", " ").split():
            if word in words:
                words[word] += 1
            else:
                words[word] = 1
    return words


def formatted_word_count_in_strings(articles):
    words = word_count_in_strings(articles)

    string = ""
    for k, v in sorted(words.items(), reverse=True, key=lambda x: x[1]):
        string += u'{0}: {1}'.format(k, v) + "\n"
    return string


def fetch_redirect(driver, article):
    link = "https://en.m.wikipedia.org/wiki" + article

    driver.get(link)

    sleep(0.4)

    split = driver.current_url.split("/")
    new_article = "/" + split[len(split) - 1]

    if new_article != article:
        print("REDIRECT: " + new_article)
    else:
        print("NO REDIRECT")
    return new_article


def run_networking_test(articles):
    create_folders()
    driver = webdriver.Safari()

    normal_articles = []
    redirecting_articles = {}
    error_articles = []

    def save_results():
        path = "/Users/andrewfinke/Desktop/WKRPython/NetworkTests/NormalArticles.plist"
        plistlib.writePlist(sorted(normal_articles), path)

        path = "/Users/andrewfinke/Desktop/WKRPython/NetworkTests/RedirectingArticles.plist"
        plistlib.writePlist(redirecting_articles, path)

        path = "/Users/andrewfinke/Desktop/WKRPython/NetworkTests/ErrorArticles.plist"
        plistlib.writePlist(sorted(error_articles), path)

    for article in articles:
        print(article)
        try:
            url = "https://en.m.wikipedia.org/wiki" + article
            html_page = urllib.request.urlopen(url, timeout=10)
            if "Redirected from" in str(BeautifulSoup(html_page, features="html.parser")):
                print("POSSIBLE REDIRECT")
                possible_redirect = fetch_redirect(driver, article)
                redirecting_articles[article] = possible_redirect
            else:
                print("VALID")
                normal_articles.append(article)
        except:
            print("ERROR: ")
            error_articles.append(article)

        if len(normal_articles) % 10 == 0:
            save_results()
    save_results()
    driver.quit()


def fetch_links_on_article(article):
    url = "https://en.m.wikipedia.org/wiki" + article
    html_page = urllib.request.urlopen(url)
    soup = BeautifulSoup(html_page)

    page_links = []
    for link in soup.findAll('a', attrs={'href': re.compile("/wiki/")}):
        href = link.get('href')
        prefix_removed = href[5:]
        if is_valid_article(prefix_removed):
            page_links.append(prefix_removed)
        else:
            print("NOT VALID: " + href)
    return sorted(list(set(page_links)), key=lambda s: s.lower())


def fetch_links_to_article(article):
    url = "https://en.m.wikipedia.org/w/index.php?title=Special:WhatLinksHere" + \
        article + "&namespace=0&limit=500&hidetrans=1&hideredirs=1"
    try:
        html_page = urllib.request.urlopen(url)
        soup = str(BeautifulSoup(html_page, features="html.parser"))
        return soup.count('/wiki/')
    except urllib.error.HTTPError as err:
        return 0


def run_pages_that_link_to_articles_test(articles):
    create_folders()

    articles_50 = {}
    articles_100 = {}
    articles_150 = {}
    articles_250 = {}
    articles_350 = {}
    articles_500 = {}
    articles_all = {}

    progress = 0
    for article in articles:
        progress += 1
        print(str(progress) + " / " + str(len(articles)))
        count = fetch_links_to_article(article)
        articles_all[article] = count
        if count < 50:
            articles_50[article] = count
        elif count < 100:
            articles_100[article] = count
        elif count < 150:
            articles_150[article] = count
        elif count < 250:
            articles_250[article] = count
        elif count < 350:
            articles_350[article] = count
        else:
            articles_500[article] = count

    def save(page_link_articles, name):
        path = "/Users/andrewfinke/Desktop/WKRPython/PageLinksTests/" + name
        plistlib.writePlist(page_link_articles, path)

    save(articles_50, "50.plist")
    save(articles_100, "100.plist")
    save(articles_150, "150.plist")
    save(articles_250, "250.plist")
    save(articles_350, "350.plist")
    save(articles_500, "500.plist")
    save(articles_all, "All.plist")


def print_random_articles(articles, count):
    results = sorted(random.sample(articles, count))
    print("\n=========\n")
    for article in results:
        print(article[1:].replace("_", " "))


def remove_articles_from_articles(articles_to_remove, articles):
    cleaned = []
    for article in articles:
        if article not in articles_to_remove:
            cleaned.append(article)
    return cleaned


def save_string_to_path(string, path):
    text_file = open(path, "w")
    text_file.write(string)
    text_file.close()


def load_articles_at_path(path):
    return plistlib.readPlist(path)


def save_articles_to_path(articles, path):
    valid = []
    for article in articles:
        if is_valid_article(article):
            valid.append(article)
    plistlib.writePlist(sorted(list(set(valid)), key=lambda s: s.lower(
    )), path)


if __name__ == "__main__":
    articles = load_articles_at_path(
        "/Users/andrewfinke/Desktop/WKRArticlesData.plist")
    run_networking_test(articles)
