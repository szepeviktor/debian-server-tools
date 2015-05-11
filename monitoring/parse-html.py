#!/usr/bin/env python3
#
# Display download URL of a Firefox addon for Windows.
#
# Usage: ./parse-html.py adblock-plus

import sys
import urllib.request
from bs4 import BeautifulSoup

firefox_addon = 'https://addons.mozilla.org'
en_us_addons = firefox_addon + '/en-US/firefox/addon/'

page = urllib.request.urlopen(en_us_addons + sys.argv[1])
html = page.read()
soup = BeautifulSoup(html)
div = soup.find('p', attrs={'class' : 'install-button'})

print(firefox_addon + div.find('a', attrs={'class' : 'windows'})['href'])
