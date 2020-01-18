#!/bin/ash

##### Functions #####
Initialise(){
   lan_ip="$(hostname -i)"
   echo -e "\n"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    ***** Starting CouchPotato/CouchPotatoServer container *****"
   if [ -z "${stack_user}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: User name not set, defaulting to 'stackman'"; stack_user="stackman"; fi
   if [ -z "${stack_password}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Password not set, defaulting to 'Skibidibbydibyodadubdub'"; stack_password="Skibidibbydibyodadubdub"; fi
   if [ -z "${user_id}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: User ID not set, defaulting to '1000'"; user_id="1000"; fi
   if [ -z "${group}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Group name not set, defaulting to 'group'"; group="group"; fi
   if [ -z "${group_id}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Group ID not set, defaulting to '1000'"; group_id="1000"; fi
   if [ -z "${video_dirs}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Video paths not set, defaulting to '/storage/videos/'"; video_dirs="/storage/videos/"; fi
   if [ -z "${movie_complete_dir}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Completed movie path not set, defaulting to '/storage/downloads/complete/movie/'"; movie_complete_dir="/storage/downloads/complete/movie/"; fi
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Local user: ${stack_user}:${user_id}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Local group: ${group}:${group_id}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    CouchPotato application directory: ${app_base_dir}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    CouchPotato configuration directory: ${config_dir}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Listening IP Address: ${lan_ip}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Video paths: ${video_dirs}"
}

CreateGroup(){
   if [ -z "$(getent group "${group}" | cut -d: -f3)" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Group ID available, creating group"
      addgroup -g "${group_id}" "${group}"
   elif [ ! "$(getent group "${group}" | cut -d: -f3)" = "${group_id}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   Group group_id mismatch - exiting"
      exit 1
   fi
}

CreateUser(){
   if [ -z "$(getent passwd "${stack_user}" | cut -d: -f3)" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    User ID available, creating user"
      adduser -s /bin/ash -H -D -G "${group}" -u "${user_id}" "${stack_user}"
   elif [ ! "$(getent passwd "${stack_user}" | cut -d: -f3)" = "${user_id}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   User ID already in use - exiting"
      exit 1
   fi
}

FirstRun(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    First run detected - create default config"
   find "${config_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
   find "${config_dir}" ! -group "${group}" -exec chgrp "${group}" {} \;
   su -m "${stack_user}" -c 'python '"${app_base_dir}/CouchPotato.py"' --data_dir '"${config_dir}"' --config_file '"${config_dir}/couchpotato.ini"' --daemon --pid_file /tmp/couchpotato.pid'
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
      -e "/^\[core\]/,/^\[.*\]/ s%^data_dir =.*%data_dir = ${config_dir}%" \
      -e "/^\[core\]/,/^\[.*\]/ s%^username =.*%username = ${stack_user}%" \
      -e "/^\[core\]/,/^\[.*\]/ s%^password =.*%password = $(echo -n "${stack_password}" | md5sum | awk '{print $1}')%" \
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
      -e "/^\[moviesearcher\]/,/^\[.*\]/ s%^cron_hour =.*%cron_hour = */2%" \
      -e "/^\[searcher\]/,/^\[.*\]/ s%^preferred_method =.*%preferred_method = nzb%" \
      -e "/^\[suggestion\]/,/^\[.*\]/ s%^enabled =.*$%enabled = False%" \
      "${config_dir}/couchpotato.ini"
   sleep 1
}

EnableSSL(){
   if [ ! -d "${config_dir}/https" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Enable HTTPS"
      mkdir -p "${config_dir}/https"
      openssl ecparam -genkey -name secp384r1 -out "${config_dir}/https/couchpotato.key"
      openssl req -new -subj "/C=NA/ST=Global/L=Global/O=CouchPotato/OU=CouchPotato/CN=CouchPotato/" -key "${config_dir}/https/couchpotato.key" -out "${config_dir}/https/couchpotato.csr"
      openssl x509 -req -sha256 -days 3650 -in "${config_dir}/https/couchpotato.csr" -signkey "${config_dir}/https/couchpotato.key" -out "${config_dir}/https/couchpotato.crt" >/dev/null 2>&1
      sed -i \
         -e "/^\[core\]/,/^\[.*\]/ s%ssl_key =.*%ssl_key = ${config_dir}/https/couchpotato.key%" \
         -e "/^\[core\]/,/^\[.*\]/ s%ssl_cert =.*%ssl_cert = ${config_dir}/https/couchpotato.crt%" \
         "${config_dir}/couchpotato.ini"
   fi
}

Configure(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Disable browser launch on startup"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Disable startup wizard"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Enable API key: ${global_api_key}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure host IP: ${lan_ip}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Disable automatic updates"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Set Video library paths: ${video_dirs}"
   sed -i \
      -e "s%^launch_browser = True$%launch_browser = False%" \
      -e "s%^show_wizard = 1$%show_wizard = 0%" \
      -e "/^\[core\]/,/^\[.*\]/ s%api_key =.*%api_key = ${global_api_key}%" \
      -e "/^\[core\]/,/^\[.*\]/ s%^host =.*%host = ${lan_ip}%" \
      -e "/^\[updater\]/,/^\[.*\]/ s%notification =.*%notification = True%" \
      -e "/^\[updater\]/,/^\[.*\]/ s%enabled =.*%enabled = True%" \
      -e "/^\[updater\]/,/^\[.*\]/ s%automatic =.*%automatic = 0%" \
      -e "/^\[manage\]/,/^\[.*\]/ s%library =.*%library = ${video_dirs//,/::}%" \
      -e "/^\[renamer\]/,/^\[.*\]/ s%from =.*%from = ${movie_complete_dir}%" \
      -e "/^\[renamer\]/,/^\[.*\]/ s%to =.*%to = ${video_dirs//,*/}%" \
      "${config_dir}/couchpotato.ini"
   if [ ! -z "${couchpotato_enabled}" ]; then
      sed -i "s%^url_base = $%url_base = /couchpotato%" "${config_dir}/couchpotato.ini"
   fi
   if [ ! -z "${kodi_headless_group_id}" ]; then
      sed -i \
         -e "/^\[xbmc\]/,/^\[.*\]/ s%enabled =.*%enabled = 1%" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s%username =.*%username = kodi%" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s%password =.*%password = ${kodi_password}%" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s%host =.*%host = kodi:8080%" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s%remote_dir_scan =.*%remote_dir_scan = 1%" \
         "${config_dir}/couchpotato.ini"
   fi
   if [ ! -z "${sabnzbd_enabled}" ]; then
      sed -i \
         -e "/^\[sabnzbd\]/,/^\[.*\]/ s%enabled =.*%enabled = 1%" \
         -e "/^\[sabnzbd\]/,/^\[.*\]/ s%category =.*%category = movie%" \
         -e "/^\[sabnzbd\]/,/^\[.*\]/ s%ssl =.*%ssl = 1%" \
         -e "/^\[sabnzbd\]/,/^\[.*\]/ s%host =.*%host = sabnzbd:9090%" \
         -e "/^\[sabnzbd\]/,/^\[.*\]/ s%api_key =.*%api_key = ${global_api_key}%" \
         "${config_dir}/couchpotato.ini"
   fi
   if [ ! -z "${deluge_enabled}" ]; then
      sed -i \
         -e "/^\[blackhole\]/,/^\[.*\]/ s%magnet_file =.*%magnet_file = 1%" \
         -e "/^\[blackhole\]/,/^\[.*\]/ s%enabled =.*%enabled = True%" \
         -e "/^\[blackhole\]/,/^\[.*\]/ s%directory =.*%directory = ${deluge_watch_dir}movie/%" \
         -e "/^\[blackhole\]/,/^\[.*\]/ s%create_subdir =.*%create_subdir = 0%" \
         -e "/^\[blackhole\]/,/^\[.*\]/ s%use_for =.*%use_for = torrent%" \
         "${config_dir}/couchpotato.ini"
   else
      sed -i \
         -e "/^\[blackhole\]/,/^\[.*\]/ s%enabled =.*%enabled = False%" \
         "${config_dir}/couchpotato.ini"
   fi
   if [ ! -z "${prowl_api_key}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configuring Prowl notifications"
      sed -i \
         -e "/^\[prowl\]/,/^\[.*\]/ s%^enabled =.*%enabled = 1%" \
         -e "/^\[prowl\]/,/^\[.*\]/ s%^api_key =.*%api_key = ${prowl_api_key}%" \
         -e "/^\[prowl\]/,/^\[.*\]/ s%^on_snatch =.*%on_snatch = 1%" \
         "${config_dir}/couchpotato.ini"
   else
      sed -i \
         -e "/^\[prowl\]/,/^\[.*\]/ s%^enabled =.*%enabled = 0%" \
         "${config_dir}/couchpotato.ini"
   fi
   if [ ! -z "${omgwtfnzbs_user}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configuring OMGWTFNZBs search provider"
      sed -i \
         -e "/^\[omgwtfnzbs\]/,/^\[.*\]/ s%^enabled =.*%enabled = 1%" \
         -e "/^\[omgwtfnzbs\]/,/^\[.*\]/ s%^username =.*%username = ${omgwtfnzbs_user}%" \
         -e "/^\[omgwtfnzbs\]/,/^\[.*\]/ s%^api_key =.*%api_key = ${omgwtfnzbs_api_key}%" \
         "${config_dir}/couchpotato.ini"
   else
      sed -i \
         -e "/^\[omgwtfnzbs\]/,/^\[.*\]/ s%^enabled =.*%enabled = 0%" \
         "${config_dir}/couchpotato.ini"
   fi
}

SetOwnerAndGroup(){
   renamer_source_dir="$(sed -nr '/\[ \]/,/\[/{/^from =/p}' "${config_dir}/couchpotato.ini" | awk '{print $3}')"
   black_hole_dir="$(sed -nr '/\[blackhole\]/,/\[/{/^directory =/p}' "${config_dir}/couchpotato.ini" | awk '{print $3}')"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Correct owner and group of application files, if required"
   find "${config_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
   find "${config_dir}" ! -group "${group}" -exec chgrp "${group}" {} \;
   find "${app_base_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
   find "${app_base_dir}" ! -group "${group}" -exec chgrp "${group}" {} \;
   if [ ! -z "${renamer_source_dir}" ]; then
      find "${renamer_source_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
      find "${renamer_source_dir}" ! -group "${group}" -exec chgrp "${group}" {} \;
   fi
   if [ ! -z "${black_hole_dir}" ]; then
      find "${black_hole_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
      find "${black_hole_dir}" ! -group "${group}" -exec chgrp "${group}" {} \;
   fi
}

LaunchCouchPotato(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Starting CouchPotato as ${stack_user}"
   su -m "${stack_user}" -c 'python '"${app_base_dir}/CouchPotato.py"' --data_dir '"${config_dir}"' --config_file '"${config_dir}/couchpotato.ini"' --console_log'
}

##### Script #####
Initialise
CreateGroup
CreateUser
if [ ! -f "${config_dir}/couchpotato.ini" ]; then FirstRun; fi
if [ ! -d "${config_dir}/https" ]; then EnableSSL; fi
Configure
SetOwnerAndGroup
LaunchCouchPotato