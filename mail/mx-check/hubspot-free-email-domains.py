#!/usr/bin/env python3
#
# List HubSpot's free email domains.

from urllib.request import urlopen
# pip3 install --user beautifulsoup4
# https://www.crummy.com/software/BeautifulSoup/bs4/doc/#strings-and-stripped-strings
from bs4 import BeautifulSoup


URL = "https://knowledge.hubspot.com/articles/kcs_article/forms/what-domains-are-blocked-when-using-the-forms-email-domains-to-block-feature"

page = urlopen(URL)
html = page.read()
soup = BeautifulSoup(html, "html.parser")

# Open an HTML file
#with open("hubspot.html") as fp:
#    soup = BeautifulSoup(fp, "html.parser")

# Original CSS selector: "#post-body span > p:not(1)"
ps = soup.select("#post-body span > p")
# Skip first paragraph
for p in ps[1:]:
    for domain in p.stripped_strings:
        print(domain)
