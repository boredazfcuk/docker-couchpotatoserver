#!/bin/ash

##### Functions #####
Initialise(){
   LANIP="$(hostname -i)"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    ***** Starting CouchPotato/CouchPotatoServer container *****"
   if [ -z "${USER}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: User name not set, defaulting to 'user'"; USER="user"; fi
   if [ -z "${UID}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: User ID not set, defaulting to '1000'"; UID="1000"; fi
   if [ -z "${GROUP}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Group name not set, defaulting to 'group'"; GROUP="group"; fi
   if [ -z "${GID}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Group ID not set, defaulting to '1000'"; GID="1000"; fi
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Local user: ${USER}:${UID}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Local group: ${GROUP}:${GID}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    CouchPotato application directory: ${APPBASE}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    CouchPotato configuration directory: ${CONFIGDIR}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Listening IP Address: ${LANIP}"
   COUCHPOTATOHOST="$(sed -nr '/\[core\]/,/\[/{/^host =/p}' "${CONFIGDIR}/settings.conf")"
   sed -i "s%^${COUCHPOTATOHOST}$%host = ${LANIP}%" "${CONFIGDIR}/settings.conf"

   if [ ! -f "${CONFIGDIR}/https" ]; then mkdir -p "${CONFIGDIR}/https"; fi

   if [ ! -f "${CONFIGDIR}/https/couchpotato.key" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Generate private key for encrypting communications"
      openssl ecparam -genkey -name secp384r1 -out "${CONFIGDIR}/https/couchpotato.key"
   fi
   if [ ! -f "${CONFIGDIR}/https/couchpotato.csr" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Create certificate request"
      openssl req -new -subj "/C=NA/ST=Global/L=Global/O=CouchPotato/OU=CouchPotato/CN=CouchPotato/" -key "${CONFIGDIR}/https/couchpotato.key" -out "${CONFIGDIR}/https/couchpotato.csr"
   fi
   if [ ! -f "${CONFIGDIR}/https/couchpotato.crt" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Generate self-signed certificate request"
      openssl x509 -req -sha256 -days 3650 -in "${CONFIGDIR}/https/couchpotato.csr" -signkey "${CONFIGDIR}/https/couchpotato.key" -out "${CONFIGDIR}/https/couchpotato.crt"
   fi

   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure CouchPotato to use ${CONFIGDIR}/https/couchpotato.key key file"
   COUCHPOTATOKEY="$(sed -nr '/\[core\]/,/\[/{/^ssl_key =/p}' "${CONFIGDIR}/settings.conf")"
   sed -i "s%^${COUCHPOTATOKEY}$%ssl_key = ${CONFIGDIR}/https/couchpotato.key%" "${CONFIGDIR}/settings.conf"

   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure CouchPotato to use ${CONFIGDIR}/https/couchpotato.crt certificate file"
   COUCHPOTATOCERT="$(sed -nr '/\[core\]/,/\[/{/^ssl_cert =/p}' "${CONFIGDIR}/settings.conf")"
   sed -i "s%^${COUCHPOTATOCERT}$%ssl_cert = ${CONFIGDIR}/https/couchpotato.crt%" "${CONFIGDIR}/settings.conf"

}

CreateGroup(){
   if [ -z "$(getent group "${GROUP}" | cut -d: -f3)" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Group ID available, creating group"
      addgroup -g "${GID}" "${GROUP}"
   elif [ ! "$(getent group "${GROUP}" | cut -d: -f3)" = "${GID}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   Group GID mismatch - exiting"
      exit 1
   fi
}

CreateUser(){
   if [ -z "$(getent passwd "${USER}" | cut -d: -f3)" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    User ID available, creating user"
      adduser -s /bin/ash -H -D -G "${GROUP}" -u "${UID}" "${USER}"
   elif [ ! "$(getent passwd "${USER}" | cut -d: -f3)" = "${UID}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   User ID already in use - exiting"
      exit 1
   fi
}

SetOwnerAndGroup(){
   RENAMERFROM="$(sed -nr '/\[renamer\]/,/\[/{/^from =/p}' "${CONFIGDIR}/settings.conf" | awk '{print $3}')"
   BLACKHOLEDIRECTORY="$(sed -nr '/\[blackhole\]/,/\[/{/^directory =/p}' "${CONFIGDIR}/settings.conf" | awk '{print $3}')"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Correct owner and group of application files, if required"
   find "${CONFIGDIR}" ! -user "${USER}" -exec chown "${USER}" {} \;
   find "${CONFIGDIR}" ! -group "${GROUP}" -exec chgrp "${GROUP}" {} \;
   find "${APPBASE}" ! -user "${USER}" -exec chown "${USER}" {} \;
   find "${APPBASE}" ! -group "${GROUP}" -exec chgrp "${GROUP}" {} \;
   if [ ! -z "${RENAMERFROM}" ]; then
      find "${RENAMERFROM}" ! -user "${USER}" -exec chown "${USER}" {} \;
      find "${RENAMERFROM}" ! -group "${GROUP}" -exec chgrp "${GROUP}" {} \;
   fi
   if [ ! -z "${BLACKHOLEDIRECTORY}" ]; then
      find "${BLACKHOLEDIRECTORY}" ! -user "${USER}" -exec chown "${USER}" {} \;
      find "${BLACKHOLEDIRECTORY}" ! -group "${GROUP}" -exec chgrp "${GROUP}" {} \;
   fi
}

LaunchCouchPotato(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Starting CouchPotato as ${USER}"
   su -m "${USER}" -c 'python '"${APPBASE}/CouchPotato.py"' --data_dir '"${CONFIGDIR}"' --console_log'
}

##### Script #####
Initialise
CreateGroup
CreateUser
SetOwnerAndGroup
LaunchCouchPotato