#!/usr/bin/env python3
"""Filter access log lines by Arcjet's well-known bot user-agent patterns."""

import argparse
import io
import json
import os
import re
import sys
import urllib.request


URL = "https://raw.githubusercontent.com/arcjet/well-known-bots/main/well-known-bots.json"
CACHE = os.path.join(
    os.path.expanduser(os.environ.get("XDG_CACHE_HOME", "~/.cache")),
    "botwatch",
    "well-known-bots.json",
)
USER_AGENT_RE = re.compile(r'"([^"]*)"$')


def read_patterns(refresh=False):
    if refresh or not os.path.exists(CACHE):
        cache_dir = os.path.dirname(CACHE)
        if not os.path.isdir(cache_dir):
            os.makedirs(cache_dir)
        with io.open(CACHE, "wb") as cache_file:
            cache_file.write(urllib.request.urlopen(URL, timeout=20).read())

    with io.open(CACHE, encoding="utf-8") as cache_file:
        data = json.load(cache_file)
    return [
        re.compile(pattern)
        for bot in data
        for pattern in bot.get("pattern", {}).get("accepted", [])
    ]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--invert", action="store_true")
    parser.add_argument("--refresh", action="store_true")
    args = parser.parse_args()

    patterns = read_patterns(args.refresh)

    for line in sys.stdin:
        match = USER_AGENT_RE.search(line.rstrip("\n"))
        if not match:
            continue

        found = any(pattern.search(match.group(1)) for pattern in patterns)
        if found != args.invert:
            print(line, end="", flush=True)


if __name__ == "__main__":
    main()
