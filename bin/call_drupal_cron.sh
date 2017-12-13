#!/bin/sh

ME=`basename "$0"`
SITE=$(echo $ME|tr '_' '.')
BASEDIR=$(dirname "$0")
CURL_CMD="curl -s "

if [ -e "$BASEDIR/$ME.vars" ]; then
  . "$BASEDIR/$ME.vars"

  if [ -z "$SCHEME" ]; then
    echo "Must supply SCHEME (https/http)"
    exit 1
  fi

  if [ -z "$HOST" ]; then
    echo "Must supply HOST (https://google.com)"
    exit 1
  fi

  if [ -z "$CRONKEY" ]; then
    echo "Must supply CRONKEY"
    exit 1
  fi

  if [ -z "$DRUPAL" ]; then
    echo "Must supply DRUPAL version (7/8)"
    exit 1
  elif [ "$DRUPAL" != "7" ] && [ "$DRUPAL" != "8" ]; then
    echo "Must be Drupal 7 or 8"
    exit 1
  fi

  # set the port
  if [ "$SCHEME" = "https" ]; then
    PORT=443
  elif [ "$SCHEME" = "http" ]; then
    PORT=80
  else
    echo "SCHEME must be http or https"
    exit 1
  fi

  # add on the resolve, if we are forcing the IP we don't want to enforce cert
  if [ -n "$HOST_IP" ]; then
    CURL_CMD="$CURL_CMD -k --resolve $HOST:$PORT:$HOST_IP "
  fi

  if [ "$DRUPAL" = "7" ]; then
    CURL_CMD="$CURL_CMD $SCHEME://$HOST/cron.php?cron_key=$CRONKEY"
  elif [[ "$DRUPAL" = "8" ]]; then
    CURL_CMD="$CURL_CMD $SCHEME://$HOST/cron/$CRONKEY"
  fi

  $CURL_CMD
fi
