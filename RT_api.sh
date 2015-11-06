#!/bin/bash
#
# Author: Ted W.
# Date: 2014-08-08
#
# This script can uses the Request Tracker REST API to interact with RT tickets.
# There is definitely a bit of work to be done here but the end goal will provide
# a script that provides the same functionality as the command by mail plugin
# would normally provide but because it uses the API it provides a layer of
# authentication instead of relying on the (spoofable) email address of the user
# making the command by email request.

# User settings
TMP="/tmp"
COOKIE_FILE="$TMP/cookies.txt"
URL="RT_Base_URL_Goes_HERE"
TEST_TICKET="1"
API="REST/1.0"

# Check for cookie file
if [ -z $COOKIE_FILE ]; then
  echo '$COOKIE_FILE variable not set, please set this in $0 and try again'
  exit 1
fi

# Test if cookie still valid
while ! curl -s -b "$COOKIE_FILE" "${URL}/${API}/ticket/1/show" | grep -q 200; do
  read -p "Enter username: " USER_NAME
  stty -echo
  read -p "Enter Password: " USER_PASS
  stty echo
  # get cookie
  curl --no-check-certificate --keep-session-cookies --save-cookies "$COOKIE_FILE" --post-data 'user='"$USER_NAME"&'pass='"$USER_PASS" "$URL"
  # above line grabs index.html, delete it to clean up somewhat
  rm index.html
done
