#!/bin/ash
exit_code=0
exit_code="$(wget --quiet --tries=1 --spider --no-check-certificate "https://${HOSTNAME}:5050/couchpotato/index.html" | echo ${?})"
if [ "${exit_code}" != 0 ]; then
   echo "WebUI not responding: Error ${exit_code}"
   exit 1
fi
echo "WebUI Available"
exit 0