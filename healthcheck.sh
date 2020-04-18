#!/bin/ash

if [ "$(netstat -plnt | grep -c 5050)" -ne 1 ]; then
   echo "CouchPotato WebUI not responding on port 5050"
   exit 1
fi

echo "CouchPotato WebUI responding on port 5050"
exit 0