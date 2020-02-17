#!/bin/ash

if [ "$(nc -z "$(hostname -i)" 5050; echo "${?}")" -ne 0 ]; then
   echo "CouchPotato WebUI not responding on port 5050"
   exit 1
fi

echo "CouchPotato WebUI responding on port 5050"
exit 0