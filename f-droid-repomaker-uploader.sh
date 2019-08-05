#!/bin/bash

# Set the environment variables $USER, $PW and $SERVER outside this script or inside the /etc/f-droid-uploader config file to use it
# Usage: <repoid> <apk> [<apk> ...]
if [ -e /etc/fdroid-repomaker-uploader ]; then
  . /etc/fdroid-repomaker-uploader
fi

set -e

log() {
  echo "$(date): $*"
}

grabCsrf() {
  TOKEN=$(cat "$PAGE" | grep csrfmi | grep -o "value=.*'" | grep -o "'.*'" | grep -o "[a-z0-9A-Z]*" | head -n 1)
}

TMP=$(mktemp -d)
JAR="$TMP/jar"
PAGE="$TMP/page"

cleanup() {
  rm -rf "$TMP"
}

trap cleanup EXIT

REPO="$1"
shift

PARAMS=(-H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' -H 'Accept-Language: de,en-US;q=0.8,en;q=0.5,pl;q=0.3' --compressed)

PARAMS+=(-b "$JAR" -c "$JAR") # cookies

PARAMS2=(-H 'DNT: 1' -H 'Connection: keep-alive' -H 'Upgrade-Insecure-Requests: 1' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' -H 'TE: Trailers')


log "Logging in as $USER @ $SERVER..."
log "Getting CSRF token..."

curl "https://$SERVER/accounts/login/?next=/" "${PARAMS[@]}" -H "Referer: https://$SERVER/accounts/logout/" "${PARAMS2[@]}" -s -o "$PAGE"

grabCsrf

log "Logging in..."

curl "https://$SERVER/accounts/login/" "${PARAMS[@]}" -H "Referer: https://$SERVER/accounts/login/?next=/" -H 'Content-Type: application/x-www-form-urlencoded' "${PARAMS2[@]}" --data "csrfmiddlewaretoken=$TOKEN&next=%2F&login=$USER&password=$PW" -s -o "$PAGE"

if [ ! -n "$PAGE" ]; then
  log "ERROR: Failed to login..." >&2
  echo
  echo
  cat "$PAGE"
fi
log "Logged in as $USER!"

curl "https://$SERVER/" "${PARAMS[@]}" -H "Referer: https://$SERVER/accounts/login/?next=/" "${PARAMS2[@]}" -s -o "$PAGE"
curl "https://$SERVER/$REPO/" "${PARAMS[@]}" -H "Referer: https://$SERVER/" "${PARAMS2[@]}" -s -o "$PAGE"
log "Uploading..."

F=()

while [ ! -z "$1" ]; do
  F+=(-F "apks=@$1")
  shift
done

grabCsrf
curl "https://$SERVER/$REPO/" "${PARAMS[@]}" -H "Referer: https://$SERVER/$REPO/" "${PARAMS2[@]}" -H 'RM-Background-Type: apks' -H "X-CSRFToken: $TOKEN" -H "X-REQUESTED-WITH: XMLHttpRequest" "${F[@]}"

