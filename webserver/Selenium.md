# Selenium

### Google Chrome browser

```bash
apt-add-repo.sh google-software
apt-get install google-chrome-stable
google-chrome --disable-gpu --headless --screenshot=screenshot.png "https://github.com/"
```

### Selenium Server

http://selenium-release.storage.googleapis.com/index.html

```
apt-get install default-jre-headless
wget "http://selenium-release.storage.googleapis.com/3.9/selenium-server-standalone-3.9.1.jar"
java -jar selenium-server-standalone-*.jar
```

### Chrome Driver

https://sites.google.com/a/chromium.org/chromedriver/downloads

```
LATEST="$(wget -q -O- http://chromedriver.storage.googleapis.com/LATEST_RELEASE)"
wget "http://chromedriver.storage.googleapis.com/${LATEST}/chromedriver_linux64.zip"
unzip chromedriver_linux64.zip
```

### WebDriver bindings for PHP

```bash
composer require facebook/webdriver
```
