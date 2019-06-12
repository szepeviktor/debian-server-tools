# Selenium

Java -> Selenium Server -> ChromeDriver -> Google Chrome

### Selenium Server

- https://www.seleniumhq.org/download/
- http://selenium-release.storage.googleapis.com/index.html

```bash
apt-get install default-jre-headless
wget "https://bit.ly/2TlkRyu"
```

### Google Chrome browser

```bash
apt-add-repo.sh google-software
apt-get install google-chrome-stable
google-chrome --disable-gpu --headless --screenshot=screenshot.png "https://github.com/"
```

### ChromeDriver

https://sites.google.com/a/chromium.org/chromedriver/downloads

```bash
LATEST="$(wget -q -O- http://chromedriver.storage.googleapis.com/LATEST_RELEASE)"
wget "http://chromedriver.storage.googleapis.com/${LATEST}/chromedriver_linux64.zip"
unzip chromedriver_linux64.zip
```

```bash
CHROME_VERSION="$(dpkg-query --showformat="\${Version}" --show google-chrome-stable|cut -d. -f1-3)"
VERSION="$( wget -qO- "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_${CHROME_VERSION}")"
echo "https://chromedriver.storage.googleapis.com/index.html?path=${VERSION}/"
echo "https://chromedriver.storage.googleapis.com/${CHROME_VERSION}/chromedriver_linux64.zip"
```

Start selenium-server-standalone.jar in an infinite loop.

### WebDriver bindings for PHP

```bash
composer require facebook/webdriver
```
