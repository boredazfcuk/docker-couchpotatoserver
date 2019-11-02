#!/bin/ash
wget --quiet --tries=1 --spider "https://${HOSTNAME}:5050/couchpotato" --no-check-certificate || exit 1
exit 0