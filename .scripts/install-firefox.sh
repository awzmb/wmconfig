#!/bin/sh

# get custom userchrome.css from github
FIREFOX_PROFILE_DIRECTORY=$(grep 'Path=' ~/.mozilla/firefox/profiles.ini | sed s/^Path=// | grep release)
for profile in ${FIREFOX_PROFILE_DIRECTORY}; do
  git clone https://github.com/awzmb/userchrome ~/.mozilla/firefox/${profile}/chrome
done

