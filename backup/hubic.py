#!/usr/bin/env python -u
# -*- coding: utf-8 -*-
#
# Access hubiC (OVH) OAuth2 API and run the OpenStack swift client.
#
# VERSION       :1.0
# DATE          :2014-08-20
# AUTHOR        :Puzzle <https://github.com/puzzle1536>
# URL           :https://github.com/szepeviktor/debian-server-tools
# DEPENDS       :pip install requests python-swiftclient
# UPSTREAM      :https://github.com/puzzle1536/hubic-wrapper-to-swift
# LOCATION      :/usr/local/bin/hubic.py
#
# Copyright 2014 - Puzzle <puzzle1536@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import requests
import json
import subprocess
import sys
import os
import ConfigParser
import re

from urlparse import parse_qsl, urlparse
from urllib import urlencode
from optparse import OptionParser, OptionGroup
from requests.auth import HTTPBasicAuth
from getpass import getpass
from stat import S_IRUSR, S_IWUSR
from time import time, strptime, mktime, strftime, localtime, timezone

class HTTPBearerAuth(requests.auth.AuthBase):
    def __init__(self, token):
        self.token = token

    def __call__(self, r):
        auth_string = "Bearer " + self.token
        r.headers['Authorization'] = auth_string
        return r

class hubic:
    def load_config(self, section, name, option, env):
        try:
            value = self.hubic_config.get(section, name)
        except (ConfigParser.NoSectionError, ConfigParser.NoOptionError):
            if option:
                value = option
            else:
                value = os.environ.get(env, 0)
        if options.verbose and value:
            print "%s=%s" % (env, value)
        return value

    def __init__(self):

        if options.verbose:
            print "-- Load environment hubic credentials:"

        # Load existing hubic config
        if options.config and os.path.exists(options.config):
            self.config_file = options.config
        else:
            self.config_file = os.path.expanduser('~/.hubic.cfg')

        try:
            self.hubic_config = ConfigParser.ConfigParser()
            self.hubic_config.read(self.config_file)
        except ConfigParser.ParsingError:
            print "Cannot read config file %s" % self.config_file
            sys.exit(1)

        # Load hubic config
        self.client_id     = self.load_config('hubic', 'client_id',     options.hubic_client_id,     'HUBIC_CLIENT_ID')
        self.client_secret = self.load_config('hubic', 'client_secret', options.hubic_client_secret, 'HUBIC_CLIENT_SECRET')
        self.redirect_uri  = self.load_config('hubic', 'redirect_uri',  options.hubic_redirect_uri,  'HUBIC_REDIRECT_URI')

        self.username      = self.load_config('hubic', 'username', options.hubic_redirect_uri, 'HUBIC_USERNAME')
        self.password      = self.load_config('hubic', 'password', options.hubic_redirect_uri, 'HUBIC_PASSWORD')

        self.access_token  = self.load_config('hubic', 'access_token',  options.hubic_access_token,  'HUBIC_ACCESS_TOKEN')
        self.refresh_token = self.load_config('hubic', 'refresh_token', options.hubic_refresh_token, 'HUBIC_REFRESH_TOKEN')

        self.os_auth_token   = self.load_config('openstack', 'os_auth_token',  options.os_auth_token,  'OS_AUTH_TOKEN')
        self.os_storage_url  = self.load_config('openstack', 'os_storage_url', options.os_storage_url, 'OS_STORAGE_URL')

        self.token_expire    = float(self.load_config('hubic',     'token_expire',     None, 'HUBIC_TOKEN_EXPIRE'))
        if options.verbose and self.token_expire:
            print "  `-- expires on %s" % strftime('%Y-%m-%d %H:%M:%S %Z', localtime(self.token_expire))
        self.os_token_expire = float(self.load_config('openstack', 'os_token_expire',  None, 'OS_TOKEN_EXPIRE'))
        if options.verbose and self.os_token_expire:
            print "  `-- expires on %s" % strftime('%Y-%m-%d %H:%M:%S %Z', localtime(self.os_token_expire))

        self.token_url = 'https://api.hubic.com/oauth/token'
        self.auth_url  = 'https://api.hubic.com/oauth/auth'
        self.oauth_code = None

    def __del__(self):
        if self.config_file:
            if options.verbose:
                print "-- Write config file back : %s " % self.config_file
            self.hubic_config = ConfigParser.RawConfigParser()

            self.hubic_config.add_section('hubic')
            if self.client_id:
                self.hubic_config.set('hubic', 'client_id', self.client_id)
            if self.client_secret:
                self.hubic_config.set('hubic', 'client_secret', self.client_secret)
            if self.redirect_uri:
                self.hubic_config.set('hubic', 'redirect_uri', self.redirect_uri)
            if self.username:
                self.hubic_config.set('hubic', 'username', self.username)
            if self.password:
                self.hubic_config.set('hubic', 'password', self.password)
            if self.refresh_token:
                self.hubic_config.set('hubic', 'refresh_token', self.refresh_token)
            if self.access_token:
                self.hubic_config.set('hubic', 'access_token', self.access_token)
            if self.token_expire:
                self.hubic_config.set('hubic', 'token_expire', self.token_expire)

            self.hubic_config.add_section('openstack')
            if self.os_auth_token:
                self.hubic_config.set('openstack', 'os_auth_token', self.os_auth_token)
            if self.os_storage_url:
                self.hubic_config.set('openstack', 'os_storage_url', self.os_storage_url)
            if self.os_token_expire:
                self.hubic_config.set('openstack', 'os_token_expire', self.os_token_expire)

            with open(self.config_file, 'wb') as configfile:
                self.hubic_config.write(configfile)
            os.chmod(self.config_file, 0600)

    def auth(self):

        # Do we have access token or an oauthid yet ?
        if not self.access_token and not self.oauth_code:

            # Request client app creds
            if not self.client_id:
                self.client_id = raw_input('HUBIC_CLIENT_ID=')
            if not self.client_secret:
                self.client_secret = raw_input('HUBIC_CLIENT_SECRET=')
            if not self.redirect_uri:
                self.redirect_uri = raw_input('HUBIC_REDIRECT_URI=')

            # Request Hubic account creds
            if not self.username:
                self.username = raw_input('Username: ')
            if not self.password:
                self.password = getpass()

            # Authorization request
            payload = {'client_id' : self.client_id,
                       'redirect_uri' : self.redirect_uri,
                       'scope' : 'usage.r,account.r,getAllLinks.r,credentials.r,activate.w,links.drw',
                       'response_type' : 'code',
                       'state' : 'none'}

            if options.verbose:
                print "-- Request hubic oauth ID:"

            r = requests.get(self.auth_url, params=payload, allow_redirects=False)

            if r.status_code != 200:
                print "Failed to request authorization code, please verify client_id or redirect_uri"
                sys.exit(1)

            try:
                oauthid = re.search('(?<=<input type="hidden" name="oauth" value=")[0-9]*', r.text).group(0)
            except:
                print "Failed to request authorization code, please verify client_id or redirect_uri"
                sys.exit(1)


            # Get request code
            payload = {'oauth' : oauthid,
                       'usage': 'r',
                       'account': 'r',
                       'getAllLinks': 'r',
                       'credentials': 'r',
                       'activate': 'w',
                       'links': 'r',
                       'action': 'accepted',
                       'login': self.username,
                       'user_pwd': self.password}

            # Add missing links d & w rights
            data = "%s&links=w&links=d" % urlencode(payload)

            headers = {'content-type': 'application/x-www-form-urlencoded'}

            if options.verbose:
                print "-- Request authorization code:"

            r = requests.post(self.auth_url, data=data, headers=headers, allow_redirects=False)

            try:
                location = urlparse(r.headers['location'])
                self.oauth_code = dict(parse_qsl(location.query))['code']
            except:
                print "Failed to request authorization code, please verify hubic username and password"
                sys.exit(2)

            return self.oauth_code

    def token(self):

        if not self.access_token:

            if not self.oauth_code:
                print "Cannot request token without oauth code"
                return

            if not self.client_id or not self.client_secret:
                if not self.client_id:
                    self.client_id = raw_input('HUBIC_CLIENT_ID=')
                if not self.client_secret:
                    self.client_secret = raw_input('HUBIC_CLIENT_SECRET=')
                if not self.redirect_uri:
                    self.redirect_uri = raw_input('HUBIC_REDIRECT_URI=')


            payload = {'code' : self.oauth_code,
                       'redirect_uri': self.redirect_uri,
                       'grant_type' : 'authorization_code'}

            if options.verbose:
                print "-- Request access token:"

            r = requests.post(self.token_url, payload,
                              auth=HTTPBasicAuth(self.client_id,self.client_secret),
                              allow_redirects=False)

            if r.status_code != 200:
                print "%s : %s" % (r.json()['error'], r.json()['error_description'])
                sys.exit(3)

            try:
                self.refresh_token = r.json()['refresh_token']
                self.access_token  = r.json()['access_token']
                self.token_expire  = time() + r.json()['expires_in']
                self.token_type    = r.json()['token_type']

            except:
                print "Something wrong has happened when requesting access token"
                sys.exit(10)

            print "HUBIC_ACCESS_TOKEN=%s" % self.access_token
            print "HUBIC_REFRESH_TOKEN=%s" % self.refresh_token
            print "HUBIC_TOKEN_EXPIRE=%s (%s)" % (self.token_expire, strftime('%Y-%m-%d %H:%M:%S %Z', localtime(self.token_expire)))
        return self.access_token

    def refresh(self):

        self.token_url = 'https://api.hubic.com/oauth/token'

        if not self.refresh_token:
            print "Cannot request new acces token without refresh token"
            sys.exit(4)

        if not self.client_id or not self.client_secret:
            if not self.client_id:
                self.client_id = raw_input('HUBIC_CLIENT_ID=')
            if not self.client_secret:
                self.client_secret = raw_input('HUBIC_CLIENT_SECRET=')
            if not self.redirect_uri:
                self.redirect_uri = raw_input('HUBIC_REDIRECT_URI=')

        payload = {'refresh_token' : self.refresh_token,
                   'grant_type' : 'refresh_token'}

        if options.verbose:
            print "-- Refresh access token:"

        r = requests.post(self.token_url, payload,
                          auth=HTTPBasicAuth(self.client_id,self.client_secret),
                          allow_redirects=False)

        if r.status_code != 200:
            print "%s : %s" % (r.json()['error'], r.json()['error_description'])
            sys.exit(4)

        try:
            self.access_token  = r.json()['access_token']
            self.token_expire  = time() + r.json()['expires_in']
            self.token_type    = r.json()['token_type']

        except:
            print "Something wrong has happened when refreshing access token"
            sys.exit(10)

        print "HUBIC_ACCESS_TOKEN=%s" % self.access_token
        print "HUBIC_TOKEN_EXPIRE=%s (%s)" % (self.token_expire, strftime('%Y-%m-%d %H:%M:%S %Z', localtime(self.token_expire)))
        return self.access_token

    def get(self, hubic_api):

        hubic_api_url = 'https://api.hubic.com/1.0%s' % hubic_api

        if self.access_token:

            if options.verbose:
                print "-- GET request to hubic API : %s" % hubic_api

            if self.token_expire <= time():
                print "-- Access token has expired, try to renew it"
                self.refresh()

            bearer_auth = HTTPBearerAuth(self.access_token)
            r = requests.get(hubic_api_url, auth=bearer_auth)

            try:
                # Check if token is still valid
                if r.status_code == 401 and r.json()['error'] == 'invalid_token' and r.json()['error_description'] == 'expired':
                    # Try to renew if possible
                    print "-- Access token has expired, try to renew it"
                    self.refresh()
                    r = requests.get(hubic_api_url, auth=bearer_auth)
                if r.status_code == 404 or r.status_code == 500:
                    print "%s : %s" % (r.json()['code'], r.json()['message'])
                    return

                if r.status_code != 200:
                    print "%s : %s" % (r.json()['error'], r.json()['error_description'])
                    return

            except:
                print "Something wrong has happened when accessing hubic API (GET request)"
                sys.exit(10)

            for keys in r.json():
                print "%s : %s" % (keys,r.json()[keys])

    def post(self, hubic_api, data):

        hubic_api_url = 'https://api.hubic.com/1.0%s' % hubic_api

        if self.access_token:

            if options.verbose:
                print "-- POST request to hubic API : %s" % hubic_api

            if self.token_expire <= time():
                print "-- Access token has expired, try to renew it"
                self.refresh()

            headers = {'content-type': 'application/x-www-form-urlencoded'}

            bearer_auth = HTTPBearerAuth(self.access_token)
            r = requests.post(hubic_api_url, data=data, headers=headers, auth=bearer_auth)

            try:
                # Check if token is still valid
                if r.status_code == 401 and r.json()['error'] == 'invalid_token' and r.json()['error_description'] == 'expired':
                    # Try to renew if possible
                    print "-- Access token has expired, try to renew it"
                    self.refresh()
                    r = requests.post(hubic_api_url, auth=bearer_auth)

                if r.status_code == 404 or r.status_code == 500:
                    print "%s : %s" % (r.json()['code'], r.json()['message'])
                    return

                if r.status_code != 200:
                    print "%s : %s" % (r.json()['error'], r.json()['error_description'])
                    return

            except:
                print "Something wrong has happened when accessing hubic API (POST request)"
                sys.exit(10)

            for keys in r.json():
                print "%s : %s" % (keys,r.json()[keys])

    def delete(self, hubic_api):

        hubic_api_url = 'https://api.hubic.com/1.0%s' % hubic_api

        if self.access_token:

            if options.verbose:
                print "-- DELETE request to hubic API : %s" % hubic_api

            if self.token_expire <= time():
                print "-- Access token has expired, try to renew it"
                self.refresh()

            bearer_auth = HTTPBearerAuth(self.access_token)
            r = requests.delete(hubic_api_url, auth=bearer_auth)

            try:
                # Check if token is still valid
                if r.status_code == 401 and r.json()['error'] == 'invalid_token' and r.json()['error_description'] == 'expired':
                    # Try to renew if possible
                    print "-- Access token has expired, try to renew it"
                    self.refresh()
                    r = requests.post(hubic_api_url, auth=bearer_auth)

                if r.status_code == 404 or r.status_code == 500:
                    print "%s : %s" % (r.json()['code'], r.json()['message'])
                    return

                if r.status_code != 200:
                    print "%s : %s" % (r.json()['error'], r.json()['error_description'])
                    return

            except:
                print "Something wrong has happened when accessing hubic API (DELETE request)"
                sys.exit(10)

            for keys in r.json():
                print "%s : %s" % (keys,r.json()[keys])

    def swift(self, args):

        self.cred_url = 'https://api.hubic.com/1.0/account/credentials'

        if self.access_token:

            if not self.os_storage_url or not self.os_auth_token or self.os_token_expire <= time() or options.os_refresh:

                # check access_token expired
                if self.token_expire <= time():
                    print "-- Access token has expired, try to renew it"
                    self.refresh()

                if options.verbose:
                    print "-- Request OpenStack token and storage url:"

                # We must first retrieve storage url and token
                bearer_auth = HTTPBearerAuth(self.access_token)
                r = requests.get(self.cred_url, auth=bearer_auth)

                if r.status_code != 200:
                    print "%s : %s" % (r.json()['error'], r.json()['error_description'])
                    sys.exit(6)

                try:
                    self.os_auth_token  = r.json()['token']
                    self.os_storage_url = r.json()['endpoint']
                    # Extract 'CEST time' from 'expires' return value
                    self.os_token_expire = mktime(strptime((r.json()['expires'])[:-6],
                                                  '%Y-%m-%dT%H:%M:%S'))
                    # Correct with local timezone
                    self.os_token_expire -= (timezone + 3600)

                except:
                    print "Something wrong has happened when requesting hubic storage credentials"
                    sys.exit(10)

                print "OS_STORAGE_URL=%s" % self.os_storage_url
                print "OS_AUTH_TOKEN=%s" % self.os_auth_token
                print "OS_TOKEN_EXPIRE=%s (%s)" % (self.os_token_expire, strftime('%Y-%m-%d %H:%M:%S %Z', localtime(self.os_token_expire)))

            if options.verbose:
                print "-- Run swift client:"

            cmd = ['swift', "--os-auth-token", self.os_auth_token, '--os-storage-url', self.os_storage_url]
            cmd.extend(args)
            subprocess.call(cmd)

if __name__ == '__main__':
    usage = "usage: %prog [options] -- [swift args]"
    parser = OptionParser(usage=usage)

    parser.add_option("-v",
                      action="store_true", dest="verbose", default=False,
                      help="Display verbose messages")

    parser.add_option("--config",
                      action="store", type="string", dest="config",
                      help="specify hubic config file to load")

    parser.add_option("--token",
                      action="store_true", dest="token", default=False,
                      help="Request Hubic token")

    parser.add_option("--refresh",
                      action="store_true", dest="refresh", default=False,
                      help="Refresh Hubic token")

    parser.add_option("--os-refresh",
                      action="store_true", dest="os_refresh", default=False,
                      help="Refresh OpenStack token")

    parser.add_option("--get",
                      action="store", type="string", dest="get",
                      help="Perform GET request to Hubic API")

    parser.add_option("--post",
                      action="store", type="string", dest="post",
                      help="Perform POST request to Hubic API")

    parser.add_option("--data",
                      action="store", type="string", dest="data",
                      help="url encoded date for POST request")

    parser.add_option("--delete",
                      action="store", type="string", dest="delete",
                      help="Perform DELETE request to Hubic API")

    parser.add_option("--swift",
                      action="store_true", dest="swift", default=False,
                      help="Call swift with all the remaining args following \"--\"")

    group = OptionGroup(parser, "Hubic access parameters")

    group.add_option("--hubic-username",
                      action="store", type="string", dest="hubic_username",
                      help="Hubic username")

    group.add_option("--hubic-password",
                      action="store", type="string", dest="hubic_password",
                      help="Hubic password")

    group.add_option("--hubic-client-id",
                      action="store", type="string", dest="hubic_client_id",
                      help="Hubic Client ID")

    group.add_option("--hubic-client-secret",
                      action="store", type="string", dest="hubic_client_secret",
                      help="Hubic Client Secret")

    group.add_option("--hubic-redirect-uri",
                      action="store", type="string", dest="hubic_redirect_uri",
                      help="Hubic Client Redirect URI")

    group.add_option("--hubic-access-token",
                      action="store", type="string", dest="hubic_access_token",
                      help="Hubic Client Redirect URI")

    group.add_option("--hubic-refresh-token",
                      action="store", type="string", dest="hubic_refresh_token",
                      help="Hubic Client Redirect URI")

    parser.add_option_group(group)

    group = OptionGroup(parser, "OpenStack Options")

    group.add_option("--os-auth-token",
                      action="store", type="string", dest="os_auth_token",
                      help="Hubic/OpenStack access token")

    group.add_option("--os-storage-url",
                      action="store", type="string", dest="os_storage_url",
                      help="Hubic/OpenStack storage URL")

    parser.add_option_group(group)

    (options, args) = parser.parse_args()

    hubic = hubic()

    # Handle requests to Hubic API
    if options.token:
        hubic.auth()
        hubic.token()

    if options.get:
        hubic.auth()
        hubic.token()
        hubic.get(options.get)

    if options.post:
        hubic.auth()
        hubic.token()
        hubic.post(options.post, options.data)

    if options.delete:
        hubic.auth()
        hubic.token()
        hubic.delete(options.delete)

    if options.refresh:
        hubic.refresh()

    if options.swift:
        hubic.auth()
        hubic.token()
        hubic.swift(args)

