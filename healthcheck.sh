#!/bin/ash
wget --quiet --tries=1 --no-check-certificate --spider "https://${HOSTNAME}:5050/couchpotato" || exit 1
exit 0