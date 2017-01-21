#!/usr/bin/env python2
#
# BeautifulSoup example script.
#
# VERSION       :0.1.0
# DEPENDS       :pip2 install beautifulsoup4

import sys
import urllib
from bs4 import BeautifulSoup

page = urllib.urlopen('https://addons.mozilla.org/en-US/firefox/addon/%s/' % sys.argv[1])
html = page.read()
soup = BeautifulSoup(html, "html.parser")
# Parses pages the same way a web browser does
#     soup = BeautifulSoup(html, "html5lib")

# http://www.crummy.com/software/BeautifulSoup/bs4/doc/
div = soup('div', attrs={'class' : 'install-wrapper'}, limit=1)

print('https://addons.mozilla.org' + div[0].a['href'])
