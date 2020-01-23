#!/bin/ash

##### Functions #####
Initialise(){
   lan_ip="$(hostname -i)"
   echo -e "\n"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    ***** Starting CouchPotato/CouchPotatoServer container *****"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Local user: ${stack_user:=stackman}:${user_id:=1000}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Local group: ${couchpotato_group:=couchpotato}:${couchpotato_group_id:=1000}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Password: ${stack_password:=Skibidibbydibyodadubdub}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    CouchPotato application directory: ${app_base_dir}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    CouchPotato configuration directory: ${config_dir}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    LAN IP Address: ${lan_ip}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Video location(s): ${video_dirs:=/storage/videos/}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Download directory: ${tv_complete_dir:=/storage/downloads/complete/movie/}"
   if [ "${couchpotato_notifications}" ]; then
      if [ "${couchpotato_notifications}" = "Prowl" ] && [ "${prowl_api_key}" ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure ${couchpotato_notifications} notifications"
      elif  [ "${couchpotato_notifications}" = "Pushbullet" ] && [ "${pushbullet_api_key}" ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure ${couchpotato_notifications} notifications"
      elif [ "${couchpotato_notifications}" = "Telegram" ] && [ "${telegram_token}" ] && [ "${telegram_chat_id}" ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure ${couchpotato_notifications} notifications"
      else
         echo "$(date '+%Y-%m-%d %H:%M:%S') WARINING ${couchpotato_notifications} notifications enabled, but configured incorrectly - disabling notifications"
         unset couchpotato_notifications prowl_api_key pushbullet_api_key telegram_token telegram_chat_id
      fi
   fi
}

CreateGroup(){
   if [ -z "$(getent group "${couchpotato_group}" | cut -d: -f3)" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Group ID available, creating group"
      addgroup -g "${couchpotato_group_id}" "${couchpotato_group}"
   elif [ ! "$(getent group "${couchpotato_group}" | cut -d: -f3)" = "${couchpotato_group_id}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   Group group_id mismatch - exiting"
      exit 1
   fi
}

CreateUser(){
   if [ -z "$(getent passwd "${stack_user}" | cut -d: -f3)" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    User ID available, creating user"
      adduser -s /bin/ash -H -D -G "${couchpotato_group}" -u "${user_id}" "${stack_user}"
   elif [ ! "$(getent passwd "${stack_user}" | cut -d: -f3)" = "${user_id}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   User ID already in use - exiting"
      exit 1
   fi
}

FirstRun(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    First run detected - create default config"
   find "${config_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
   find "${config_dir}" ! -group "${couchpotato_group}" -exec chgrp "${couchpotato_group}" {} \;
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
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Initialise HTTPS"
      mkdir -p "${config_dir}/https"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Generate server key"
      openssl ecparam -genkey -name secp384r1 -out "${config_dir}/https/couchpotato.key"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Generate certificate request"
      openssl req -new -subj "/C=NA/ST=Global/L=Global/O=CouchPotato/OU=CouchPotato/CN=CouchPotato/" -key "${config_dir}/https/couchpotato.key" -out "${config_dir}/https/couchpotato.csr"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Generate certificate"
      openssl x509 -req -sha256 -days 3650 -in "${config_dir}/https/couchpotato.csr" -signkey "${config_dir}/https/couchpotato.key" -out "${config_dir}/https/couchpotato.crt" >/dev/null 2>&1
   fi
   if [ -f "${config_dir}/https/couchpotato.key" ] && [ -f "${config_dir}/https/couchpotato.crt" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure CouchPotato to use HTTPS"
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
   if [ "${couchpotato_enabled}" ]; then
      sed -i "s%^url_base = $%url_base = /couchpotato%" "${config_dir}/couchpotato.ini"
   fi
   if [ "${kodi_headless_group_id}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Kodi-headless enabled"
      sed -i \
         -e "/^\[xbmc\]/,/^\[.*\]/ s%enabled =.*%enabled = 1%" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s%username =.*%username = kodi%" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s%password =.*%password = ${kodi_password}%" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s%host =.*%host = kodi:8080%" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s%remote_dir_scan =.*%remote_dir_scan = 1%" \
         "${config_dir}/couchpotato.ini"
   fi
   if [ "${sabnzbd_enabled}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Sabnzbd enabled"
      sed -i \
         -e "/^\[sabnzbd\]/,/^\[.*\]/ s%enabled =.*%enabled = 1%" \
         -e "/^\[sabnzbd\]/,/^\[.*\]/ s%category =.*%category = movie%" \
         -e "/^\[sabnzbd\]/,/^\[.*\]/ s%ssl =.*%ssl = 1%" \
         -e "/^\[sabnzbd\]/,/^\[.*\]/ s%host =.*%host = sabnzbd:9090%" \
         -e "/^\[sabnzbd\]/,/^\[.*\]/ s%api_key =.*%api_key = ${global_api_key}%" \
         "${config_dir}/couchpotato.ini"
   fi
   if [ "${deluge_enabled}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Deluge enabled"
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
   if [ "${prowl_api_key}" ] && [ "${couchpotato_notifications}" = "Prowl" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Prowl notifications enabled"
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
   if [ "${telegram_token}" ] && [ "${couchpotato_notifications}" = "Telegram" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Telegram notifications enabled"
      sed -i \
         -e "/^\[telegrambot\]/,/^\[.*\]/ s%^enabled =.*%enabled = 1%" \
         -e "/^\[telegrambot\]/,/^\[.*\]/ s%^bot_token =.*%bot_token = ${telegram_token}%" \
         -e "/^\[telegrambot\]/,/^\[.*\]/ s%^receiver_user_id =.*%receiver_user_id = ${telegram_chat_id=}%" \
         "${config_dir}/couchpotato.ini"
   else
      sed -i \
         -e "/^\[telegrambot\]/,/^\[.*\]/ s%^enabled =.*%enabled = 0%" \
         "${config_dir}/couchpotato.ini"
   fi
   if [ "${omgwtfnzbs_user}" ]; then
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
   find "${config_dir}" ! -group "${couchpotato_group}" -exec chgrp "${couchpotato_group}" {} \;
   find "${app_base_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
   find "${app_base_dir}" ! -group "${couchpotato_group}" -exec chgrp "${couchpotato_group}" {} \;
   if [ "${renamer_source_dir}" ]; then
      find "${renamer_source_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
      find "${renamer_source_dir}" ! -group "${couchpotato_group}" -exec chgrp "${couchpotato_group}" {} \;
   fi
   if [ "${black_hole_dir}" ]; then
      find "${black_hole_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
      find "${black_hole_dir}" ! -group "${couchpotato_group}" -exec chgrp "${couchpotato_group}" {} \;
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
EnableSSL
Configure
SetOwnerAndGroup
LaunchCouchPotato