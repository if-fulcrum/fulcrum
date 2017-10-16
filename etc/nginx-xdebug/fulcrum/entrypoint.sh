#!/bin/sh
# Nginx does not use etc hosts and uses a dns server
# to look up host names... so we need to put the
# ips in the config to get around this bug.
MYFILE=/etc/nginx/fulcrum/fulcrum_phpversion
if [ -e ${MYFILE}.template ]; then

  cp ${MYFILE}.template ${MYFILE}.conf

  while read -r LINE ; do
    IP=$( echo $LINE| awk '{ print $1 }' )
    HOST=$( echo $LINE| awk '{ print $2 }' )
    if [ -z "${LINE##*php*}" ]; then
      sed -i "s;${HOST};${IP};g" ${MYFILE}.conf
    fi
  done < /etc/hosts

fi
/usr/sbin/nginx
