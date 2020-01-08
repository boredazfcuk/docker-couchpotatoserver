#!/bin/ash

##### Functions #####
Initialise(){
   LANIP="$(hostname -i)"
   echo -e "\n"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    ***** Starting CouchPotato/CouchPotatoServer container *****"
   if [ -z "${STACKUSER}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: User name not set, defaulting to 'stackman'"; STACKUSER="stackman"; fi
   if [ -z "${STACKPASSWORD}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Password not set, defaulting to 'Skibidibbydibyodadubdub'"; STACKPASSWORD="Skibidibbydibyodadubdub"; fi
   if [ -z "${UID}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: User ID not set, defaulting to '1000'"; UID="1000"; fi
   if [ -z "${GROUP}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Group name not set, defaulting to 'group'"; GROUP="group"; fi
   if [ -z "${GID}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Group ID not set, defaulting to '1000'"; GID="1000"; fi
   if [ -z "${VIDEODIRS}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Video paths not set, defaulting to '/storage/videos/'"; VIDEODIRS="/storage/videos/"; fi
   if [ -z "${MOVIECOMPLETEDIR}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Completed movie path not set, defaulting to '/storage/downloads/complete/movie/'"; MOVIECOMPLETEDIR="/storage/downloads/complete/movie/"; fi
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Local user: ${STACKUSER}:${UID}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Local group: ${GROUP}:${GID}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    CouchPotato application directory: ${APPBASE}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    CouchPotato configuration directory: ${CONFIGDIR}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Listening IP Address: ${LANIP}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Video paths: ${VIDEODIRS}"
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
   if [ -z "$(getent passwd "${STACKUSER}" | cut -d: -f3)" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    User ID available, creating user"
      adduser -s /bin/ash -H -D -G "${GROUP}" -u "${UID}" "${STACKUSER}"
   elif [ ! "$(getent passwd "${STACKUSER}" | cut -d: -f3)" = "${UID}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   User ID already in use - exiting"
      exit 1
   fi
}

FirstRun(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    First run detected - create default config"
   find "${CONFIGDIR}" ! -user "${STACKUSER}" -exec chown "${STACKUSER}" {} \;
   find "${CONFIGDIR}" ! -group "${GROUP}" -exec chgrp "${GROUP}" {} \;
   su -m "${STACKUSER}" -c 'python '"${APPBASE}/CouchPotato.py"' --data_dir '"${CONFIGDIR}"' --config_file '"${CONFIGDIR}/couchpotato.ini"' --daemon --pid_file /tmp/couchpotato.pid'
   sleep 15
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    ***** Reload CouchPotato/CouchPotatoServer *****"
   pkill python
   sleep 5
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Add host setting"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Set unrar path: /usr/bin/unrar"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure library refresh interval to 12hr"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Disable usenet and torrent searchers"
   sed -i \
      -e "/^\[core]/ ahost = " \
      -e "/^\[core\]/,/^\[.*\]/ s%^dark_theme =.*%dark_theme = True%" \
      -e "/^\[core\]/,/^\[.*\]/ s%^data_dir =.*%data_dir = ${CONFIGDIR}%" \
      -e "/^\[core\]/,/^\[.*\]/ s%^username =.*%username = ${STACKUSER}%" \
      -e "/^\[core\]/,/^\[.*\]/ s%^password =.*%password = $(echo -n "${STACKPASSWORD}" | md5sum | awk '{print $1}')%" \
      -e "/^\[core\]/,/^\[.*\]/ s%^provider_order = omgwtfnzbs magnetdl%provider_order = omgwtfnzbs magnetdl%" \
      -e "/^\[manage\]/,/^\[.*\]/ s%^enabled = False%enabled = True%" \
      -e "/^\[manage\]/,/^\[.*\]/ s%^library_refresh_interval = 0%library_refresh_interval = 12%" \
      -e "/^\[renamer\]/,/^\[.*\]/ s%^enabled =.*$%enabled = 1%" \
      -e "/^\[renamer\]/,/^\[.*\]/ s%^unrar =.*%unrar = 1%" \
      -e "/^\[renamer\]/,/^\[.*\]/ s%^unrar_path = $%unrar_path = /usr/bin/unrar%" \
      -e "/^\[renamer\]/,/^\[.*\]/ s%^run_every =.*%run_every = 0%" \
      -e "/^\[renamer\]/,/^\[.*\]/ s%^next_on_failed =.*%next_on_failed = True%" \
      -e "/^\[renamer\]/,/^\[.*\]/ s%^cleanup =.*%cleanup = True%" \
      -e "/^\[renamer\]/,/^\[.*\]/ s%^check_space =.*%check_space = True%" \
      -e "/^\[renamer\]/,/^\[.*\]/ s%^file_action =.*%file_action = symlink_reversed%" \
      -e '/^\[renamer\]/,/^\[.*\]/ s%^folder_name =.*%folder_name = <thename> (<year>)' \
      -e '/^\[renamer\]/,/^\[.*\]/ s%^file_name =.*%file_name = <thename><cd>.<ext>' \
      -e "/^\[newznab\]/,/^\[.*\]/ s%^enabled =.*$%enabled = 0%" \
      -e "/^\[searcher\]/,/^\[.*\]/ s%^preferred_method =.*%preferred_method = nzb%" \
      -e "/^\[suggestion\]/,/^\[.*\]/ s%^enabled =.*$%enabled = False%" \
      "${CONFIGDIR}/couchpotato.ini"
   sleep 1
}

EnableSSL(){
   if [ ! -d "${CONFIGDIR}/https" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Enable HTTPS"
      mkdir -p "${CONFIGDIR}/https"
      openssl ecparam -genkey -name secp384r1 -out "${CONFIGDIR}/https/couchpotato.key"
      openssl req -new -subj "/C=NA/ST=Global/L=Global/O=CouchPotato/OU=CouchPotato/CN=CouchPotato/" -key "${CONFIGDIR}/https/couchpotato.key" -out "${CONFIGDIR}/https/couchpotato.csr"
      openssl x509 -req -sha256 -days 3650 -in "${CONFIGDIR}/https/couchpotato.csr" -signkey "${CONFIGDIR}/https/couchpotato.key" -out "${CONFIGDIR}/https/couchpotato.crt" >/dev/null 2>&1
      sed -i \
         -e "/^\[core\]/,/^\[.*\]/ s%ssl_key =.*%ssl_key = ${CONFIGDIR}/https/couchpotato.key%" \
         -e "/^\[core\]/,/^\[.*\]/ s%ssl_cert =.*%ssl_cert = ${CONFIGDIR}/https/couchpotato.crt%" \
         "${CONFIGDIR}/couchpotato.ini"
   fi
}

Configure(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Disable browser launch on startup"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Disable startup wizard"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Enable API key: ${GLOBALAPIKEY}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure host IP: ${LANIP}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Disable automatic updates"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Set Video library paths: ${VIDEODIRS}"
   sed -i \
      -e "s%^launch_browser = True$%launch_browser = False%" \
      -e "s%^show_wizard = 1$%show_wizard = 0%" \
      -e "/^\[core\]/,/^\[.*\]/ s%api_key =.*%api_key = ${GLOBALAPIKEY}%" \
      -e "/^\[core\]/,/^\[.*\]/ s%^host =.*%host = ${LANIP}%" \
      -e "/^\[updater\]/,/^\[.*\]/ s%notification =.*%notification = True%" \
      -e "/^\[updater\]/,/^\[.*\]/ s%enabled =.*%enabled = True%" \
      -e "/^\[updater\]/,/^\[.*\]/ s%automatic =.*%automatic = 0%" \
      -e "/^\[manage\]/,/^\[.*\]/ s%library =.*%library = ${VIDEODIRS//,/::}%" \
      -e "/^\[renamer\]/,/^\[.*\]/ s%from =.*%from = ${MOVIECOMPLETEDIR}%" \
      -e "/^\[renamer\]/,/^\[.*\]/ s%to =.*%to = ${VIDEODIRS//,*/}%" \
      "${CONFIGDIR}/couchpotato.ini"
   if [ ! -z "${COUCHPOTATOENABLED}" ]; then
      sed -i "s%^url_base = $%url_base = /couchpotato%" "${CONFIGDIR}/couchpotato.ini"
   fi
   if [ ! -z "${KODIHEADLESS}" ]; then
      sed -i \
         -e "/^\[xbmc\]/,/^\[.*\]/ s%enabled =.*%enabled = 1%" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s%username =.*%username = kodi%" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s%password =.*%password = ${KODIPASSWORD}%" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s%host =.*%host = kodi:8080%" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s%remote_dir_scan =.*%remote_dir_scan = 1%" \
         "${CONFIGDIR}/couchpotato.ini"
   fi
   if [ ! -z "${SABNZBDENABLED}" ]; then
      sed -i \
         -e "/^\[sabnzbd\]/,/^\[.*\]/ s%enabled =.*%enabled = 1%" \
         -e "/^\[sabnzbd\]/,/^\[.*\]/ s%category =.*%category = movie%" \
         -e "/^\[sabnzbd\]/,/^\[.*\]/ s%ssl =.*%ssl = 1%" \
         -e "/^\[sabnzbd\]/,/^\[.*\]/ s%host =.*%host = sabnzbd:9090%" \
         -e "/^\[sabnzbd\]/,/^\[.*\]/ s%api_key =.*%api_key = ${GLOBALAPIKEY}%" \
         "${CONFIGDIR}/couchpotato.ini"
   fi
   if [ ! -z "${DELUGEENABLED}" ]; then
      sed -i \
         -e "/^\[blackhole\]/,/^\[.*\]/ s%magnet_file =.*%magnet_file = 1%" \
         -e "/^\[blackhole\]/,/^\[.*\]/ s%enabled =.*%enabled = True%" \
         -e "/^\[blackhole\]/,/^\[.*\]/ s%directory =.*%directory = ${DELUGEWATCHDIR}movie/%" \
         -e "/^\[blackhole\]/,/^\[.*\]/ s%create_subdir =.*%create_subdir = 0%" \
         -e "/^\[blackhole\]/,/^\[.*\]/ s%use_for =.*%use_for = torrent%" \
         "${CONFIGDIR}/couchpotato.ini"
   else
      sed -i \
         -e "/^\[blackhole\]/,/^\[.*\]/ s%enabled =.*%enabled = False%" \
         "${CONFIGDIR}/couchpotato.ini"
   fi
   if [ ! -z "${PROWLAPI}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configuring Prowl notifications"
      sed -i \
         -e "/^\[prowl\]/,/^\[.*\]/ s%^enabled =.*%enabled = 1%" \
         -e "/^\[prowl\]/,/^\[.*\]/ s%^api_key =.*%api_key = ${PROWLAPI}%" \
         -e "/^\[prowl\]/,/^\[.*\]/ s%^on_snatch =.*%on_snatch = 1%" \
         "${CONFIGDIR}/couchpotato.ini"
   else
      sed -i \
         -e "/^\[prowl\]/,/^\[.*\]/ s%^enabled =.*%enabled = 0%" \
         "${CONFIGDIR}/couchpotato.ini"
   fi
   if [ ! -z "${OMGWTFNZBS}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configuring OMGWTFNZBs search provider"
      sed -i \
         -e "/^\[omgwtfnzbs\]/,/^\[.*\]/ s%^enabled =.*%enabled = 1%" \
         -e "/^\[omgwtfnzbs\]/,/^\[.*\]/ s%^username =.*%username = ${OMGWTFNZBS}%" \
         -e "/^\[omgwtfnzbs\]/,/^\[.*\]/ s%^api_key =.*%api_key = ${OMGWTFNZBSAPI}%" \
         "${CONFIGDIR}/couchpotato.ini"
   else
      sed -i \
         -e "/^\[omgwtfnzbs\]/,/^\[.*\]/ s%^enabled =.*%enabled = 0%" \
         "${CONFIGDIR}/couchpotato.ini"
   fi
}

SetOwnerAndGroup(){
   RENAMERFROM="$(sed -nr '/\[ \]/,/\[/{/^from =/p}' "${CONFIGDIR}/couchpotato.ini" | awk '{print $3}')"
   BLACKHOLEDIRECTORY="$(sed -nr '/\[blackhole\]/,/\[/{/^directory =/p}' "${CONFIGDIR}/couchpotato.ini" | awk '{print $3}')"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Correct owner and group of application files, if required"
   find "${CONFIGDIR}" ! -user "${STACKUSER}" -exec chown "${STACKUSER}" {} \;
   find "${CONFIGDIR}" ! -group "${GROUP}" -exec chgrp "${GROUP}" {} \;
   find "${APPBASE}" ! -user "${STACKUSER}" -exec chown "${STACKUSER}" {} \;
   find "${APPBASE}" ! -group "${GROUP}" -exec chgrp "${GROUP}" {} \;
   if [ ! -z "${RENAMERFROM}" ]; then
      find "${RENAMERFROM}" ! -user "${STACKUSER}" -exec chown "${STACKUSER}" {} \;
      find "${RENAMERFROM}" ! -group "${GROUP}" -exec chgrp "${GROUP}" {} \;
   fi
   if [ ! -z "${BLACKHOLEDIRECTORY}" ]; then
      find "${BLACKHOLEDIRECTORY}" ! -user "${STACKUSER}" -exec chown "${STACKUSER}" {} \;
      find "${BLACKHOLEDIRECTORY}" ! -group "${GROUP}" -exec chgrp "${GROUP}" {} \;
   fi
}

LaunchCouchPotato(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Starting CouchPotato as ${STACKUSER}"
   su -m "${STACKUSER}" -c 'python '"${APPBASE}/CouchPotato.py"' --data_dir '"${CONFIGDIR}"' --config_file '"${CONFIGDIR}/couchpotato.ini"' --console_log'
}

##### Script #####
Initialise
CreateGroup
CreateUser
if [ ! -f "${CONFIGDIR}/couchpotato.ini" ]; then FirstRun; fi
if [ ! -d "${CONFIGDIR}/https" ]; then EnableSSL; fi
Configure
SetOwnerAndGroup
LaunchCouchPotato