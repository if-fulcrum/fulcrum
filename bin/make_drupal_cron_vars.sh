#!/bin/sh

CRON_DIR=/usr/local/fulcrum/etc/cron/periodic/01min

# see if we were given a domain
HOST=${1:-""}

# ask if we didn't find a domain
if [ -z "$HOST" ]; then
  read -p "Please enter host you would like to add to cron: " HOST
fi

# see if we were given a cron key
CRONKEY=${2:-""}

# ask if we didn't find a cron key
if [ -z "$CRONKEY" ]; then
  read -p "Please enter the cron key for this host: " CRONKEY
fi

# see if we were given a scheme
SCHEME=${3:-""}

# ask if we didn't find a scheme
if [ -z "$SCHEME" ]; then
  read -p "Please enter the scheme for the host [default: http]: " SCHEME

  if [ -z "$SCHEME" ]; then
    SCHEME="http"
  fi
fi

# see if we were given a version
DRUPAL=${4:-""}

# ask if we didn't find a version
if [ -z "$DRUPAL" ]; then
  read -p "Please enter the Drupal version of host [default: 7]: " DRUPAL

  if [ -z "$DRUPAL" ]; then
    DRUPAL="7"
  fi
fi

VARS="HOST=$HOST
CRONKEY=$CRONKEY
SCHEME=$SCHEME
DRUPAL=$DRUPAL"

# see if we were given a host IP
HOST_IP=${5:-""}

# ask if we didn't find a host IP
if [ -n "$HOST_IP" ]; then
  VARS="$VARS
HOST_IP=$HOST_IP"
fi

SAFENAME=$(echo $HOST|tr '.' '_')
FILENAME=$SAFENAME.vars

# write the vars file
echo "$VARS" > $CRON_DIR/$FILENAME

# make the symlink
ln -s call_drupal_cron.sh $CRON_DIR/$SAFENAME
