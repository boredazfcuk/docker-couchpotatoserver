#!/bin/ash

if [ "$(netstat -plnt | grep -c 5050)" -ne 1 ]; then
   echo "CouchPotato WebUI not responding on port 5050"
   exit 1
fi

if [ "$(hostname -i 2>/dev/null | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | wc -l)" -eq 0 ]; then
   echo "NIC missing"
   exit 1
fi

echo "CouchPotato WebUI responding on port 5050"
exit 0