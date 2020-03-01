#!/bin/ash

##### Functions #####
InitialiseVariables(){
   lan_ip="$(hostname -i)"
   echo -e "\n"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    ***** Configuring CouchPotato container launch environment *****"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Local user: ${stack_user:=stackman}:${user_id:=1000}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Local group: ${couchpotato_group:=couchpotato}:${couchpotato_group_id:=1000}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Password: ${stack_password:=Skibidibbydibyodadubdub}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    CouchPotato application directory: ${app_base_dir}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    CouchPotato configuration directory: ${config_dir}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    LAN IP Address: ${lan_ip}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Video location(s): ${video_dirs:=/storage/videos/}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Download complete directory: ${movie_complete_dir:=/storage/downloads/complete/movie/}"
   if [ "${deluge_enabled}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Deluge incoming download directory: ${deluge_incoming_dir:=/storage/downloads/incoming/deluge/}"
   fi
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
   if [ ! -f "${config_dir}/couchpotato.ini" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    First run detected - create default config"
      find "${config_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
      find "${config_dir}" ! -group "${couchpotato_group}" -exec chgrp "${couchpotato_group}" {} \;
      su -p "${stack_user}" -c 'python '"${app_base_dir}/CouchPotato.py"' --data_dir '"${config_dir}"' --config_file '"${config_dir}/couchpotato.ini"' --daemon --pid_file /tmp/couchpotato.pid'
      sleep 15
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    ***** Reload CouchPotato launch environment *****"
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
         -e "/^\[manage\]/,/^\[.*\]/ s%^enabled = False%enabled = True%" \
         -e "/^\[manage\]/,/^\[.*\]/ s%^library_refresh_interval = 0%library_refresh_interval = 12%" \
         -e "/^\[renamer\]/,/^\[.*\]/ s%^enabled =.*%enabled = True%" \
         -e "/^\[renamer\]/,/^\[.*\]/ s%^unrar =.*%unrar = True%" \
         -e "/^\[renamer\]/,/^\[.*\]/ s%^unrar_path =.*%unrar_path = /usr/bin/unrar%" \
         -e "/^\[renamer\]/,/^\[.*\]/ s%^run_every =.*%run_every = 0%" \
         -e "/^\[renamer\]/,/^\[.*\]/ s%^next_on_failed =.*%next_on_failed = True%" \
         -e "/^\[renamer\]/,/^\[.*\]/ s%^cleanup =.*%cleanup = True%" \
         -e "/^\[renamer\]/,/^\[.*\]/ s%^check_space =.*%check_space = True%" \
         -e "/^\[renamer\]/,/^\[.*\]/ s%^file_action =.*%file_action = symlink_reversed%" \
         -e '/^\[renamer\]/,/^\[.*\]/ s%^folder_name =.*%folder_name = <thename> (<year>)%' \
         -e '/^\[renamer\]/,/^\[.*\]/ s%^file_name =.*%file_name = <thename><cd>.<ext>%' \
         -e "/^\[newznab\]/,/^\[.*\]/ s%^enabled =.*$%enabled = False%" \
         -e "/^\[moviesearcher\]/,/^\[.*\]/ s%^cron_hour =.*%cron_hour = */2%" \
         -e "/^\[moviesearcher\]/,/^\[.*\]/ s%^run_on_launch =.*%run_on_launch = True%" \
         -e "/^\[searcher\]/,/^\[.*\]/ s%^preferred_method =.*%preferred_method = nzb%" \
         -e "/^\[suggestion\]/,/^\[.*\]/ s%^enabled =.*$%enabled = False%" \
         -e "/^\[blackhole\]/,/^\[.*\]/ s%enabled =.*%enabled = False%" \
         "${config_dir}/couchpotato.ini"
      sleep 2
   fi
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
      -e "s%^show_wizard =.*%show_wizard = False%" \
      -e "/^\[core\]/,/^\[.*\]/ s%api_key =.*%api_key = ${global_api_key}%" \
      -e "/^\[core\]/,/^\[.*\]/ s%^host =.*%host = ${lan_ip}%" \
      -e "/^\[updater\]/,/^\[.*\]/ s%notification =.*%notification = True%" \
      -e "/^\[updater\]/,/^\[.*\]/ s%enabled =.*%enabled = True%" \
      -e "/^\[updater\]/,/^\[.*\]/ s%automatic =.*%automatic = False%" \
      -e "/^\[manage\]/,/^\[.*\]/ s%library =.*%library = ${video_dirs//,/::}%" \
      -e "/^\[renamer\]/,/^\[.*\]/ s%from =.*%from = ${movie_complete_dir}%" \
      -e "/^\[renamer\]/,/^\[.*\]/ s%to =.*%to = ${video_dirs//,*/}%" \
      "${config_dir}/couchpotato.ini"
   if [ "${couchpotato_enabled}" ]; then
      sed -i "s%^url_base = .*%url_base = /couchpotato%" "${config_dir}/couchpotato.ini"
   fi
}

Kodi(){
   if [ "${kodi_enabled}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Kodi-headless enabled"
      sed -i \
         -e "/^\[xbmc\]/,/^\[.*\]/ s%enabled =.*%enabled = True%" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s%username =.*%username = kodi%" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s%password =.*%password = ${kodi_password}%" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s%host =.*%host = kodi:8080%" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s%remote_dir_scan =.*%remote_dir_scan = True%" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s/meta_disc_art =.*/meta_disc_art = True/" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s/meta_disc_art_name =.*/meta_disc_art_name = %s-disc.png/" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s/meta_thumbnail =.*/meta_thumbnail = True/" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s/meta_thumbnail_name =.*/meta_thumbnail_name = %s-thumb.jpg/" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s/meta_fanart =.*/meta_fanart = True/" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s/meta_fanart_name =.*/meta_fanart_name = %s-fanart.jpg/" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s/meta_logo =.*/meta_logo = True/" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s/meta_logo_name =.*/meta_logo_name = %s-logo.jpg/" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s/meta_clear_art =.*/meta_clear_art = True/" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s/meta_clear_art_name =.*/meta_clear_art_name = %s-clearart.png/" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s/meta_landscape =.*/meta_landscape = True/" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s/meta_landscape_name =.*/meta_landscape_name = %s-landscape.jpg/" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s/meta_banner =.*/meta_banner = True/" \
         -e "/^\[xbmc\]/,/^\[.*\]/ s/meta_banner_name =.*/meta_banner_name = %s-banner.jpg/" \
         "${config_dir}/couchpotato.ini"
   fi
}

SABnzbd(){
   if [ "${sabnzbd_enabled}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Sabnzbd enabled"
      sed -i \
         -e "/^\[sabnzbd\]/,/^\[.*\]/ s%enabled =.*%enabled = True%" \
         -e "/^\[sabnzbd\]/,/^\[.*\]/ s%category =.*%category = movie%" \
         -e "/^\[sabnzbd\]/,/^\[.*\]/ s%ssl =.*%ssl = True%" \
         -e "/^\[sabnzbd\]/,/^\[.*\]/ s%host =.*%host = sabnzbd:9090%" \
         -e "/^\[sabnzbd\]/,/^\[.*\]/ s%api_key =.*%api_key = ${global_api_key}%" \
         "${config_dir}/couchpotato.ini"
   fi
}

Deluge(){
   if [ "${deluge_enabled}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Deluge enabled"
      sed -i \
         -e "/^\[deluge\]/,/^\[.*\]/ s%username =.*%username = ${stack_user}%" \
         -e "/^\[deluge\]/,/^\[.*\]/ s%enabled =.*%enabled = True%" \
         -e "/^\[deluge\]/,/^\[.*\]/ s%label =.*%label = movie%" \
         -e "/^\[deluge\]/,/^\[.*\]/ s%host =.*%host = localhost:58846%" \
         -e "/^\[deluge\]/,/^\[.*\]/ s%password =.*%password = ${stack_password}%" \
         -e "/^\[deluge\]/,/^\[.*\]/ s%directory =.*%directory = ${deluge_incoming_dir}%" \
         -e "/^\[deluge\]/,/^\[.*\]/ s%completed_directory =.*%completed_directory = ${movie_complete_dir}%" \
         -e "/^\[magnetdl\]/,/^\[.*\]/ s%enabled =.*%enabled = True%" \
         "${config_dir}/couchpotato.ini"
   else
      sed -i \
         -e "/^\[deluge\]/,/^\[.*\]/ s%enabled =.*%enabled = False%" \
         "${config_dir}/couchpotato.ini"
   fi
}

Prowl(){
   if [ "${prowl_api_key}" ] && [ "${couchpotato_notifications}" = "Prowl" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Prowl notifications enabled"
      sed -i \
         -e "/^\[prowl\]/,/^\[.*\]/ s%^enabled =.*%enabled = True%" \
         -e "/^\[prowl\]/,/^\[.*\]/ s%^api_key =.*%api_key = ${prowl_api_key}%" \
         -e "/^\[prowl\]/,/^\[.*\]/ s%^on_snatch =.*%on_snatch = True%" \
         "${config_dir}/couchpotato.ini"
   else
      sed -i \
         -e "/^\[prowl\]/,/^\[.*\]/ s%^enabled =.*%enabled = False%" \
         "${config_dir}/couchpotato.ini"
   fi
}

Telegram(){
   if [ "${telegram_token}" ] && [ "${couchpotato_notifications}" = "Telegram" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Telegram notifications enabled"
      sed -i \
         -e "/^\[telegrambot\]/,/^\[.*\]/ s%^enabled =.*%enabled = True%" \
         -e "/^\[telegrambot\]/,/^\[.*\]/ s%^bot_token =.*%bot_token = ${telegram_token}%" \
         -e "/^\[telegrambot\]/,/^\[.*\]/ s%^receiver_user_id =.*%receiver_user_id = ${telegram_chat_id=}%" \
         "${config_dir}/couchpotato.ini"
   else
      sed -i \
         -e "/^\[telegrambot\]/,/^\[.*\]/ s%^enabled =.*%enabled = False%" \
         "${config_dir}/couchpotato.ini"
   fi
}

OMGWTFNZBs(){
   if [ "${omgwtfnzbs_user}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configuring OMGWTFNZBs search provider"
      sed -i \
         -e "/^\[omgwtfnzbs\]/,/^\[.*\]/ s%^enabled =.*%enabled = True%" \
         -e "/^\[omgwtfnzbs\]/,/^\[.*\]/ s%^username =.*%username = ${omgwtfnzbs_user}%" \
         -e "/^\[omgwtfnzbs\]/,/^\[.*\]/ s%^api_key =.*%api_key = ${omgwtfnzbs_api_key}%" \
         "${config_dir}/couchpotato.ini"
   else
      sed -i \
         -e "/^\[omgwtfnzbs\]/,/^\[.*\]/ s%^enabled =.*%enabled = False%" \
         "${config_dir}/couchpotato.ini"
   fi
}

SetOwnerAndGroup(){
   renamer_source_dir="$(sed -nr '/\[ \]/,/\[/{/^from =/p}' "${config_dir}/couchpotato.ini" | awk '{print $3}')"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Correct owner and group of application files, if required"
   find "${config_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
   find "${config_dir}" ! -group "${couchpotato_group}" -exec chgrp "${couchpotato_group}" {} \;
   find "${app_base_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
   find "${app_base_dir}" ! -group "${couchpotato_group}" -exec chgrp "${couchpotato_group}" {} \;
   find "${movie_complete_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
   find "${movie_complete_dir}" ! -group "${couchpotato_group}" -exec chgrp "${couchpotato_group}" {} \;
   if [ "${renamer_source_dir}" ]; then
      find "${renamer_source_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
      find "${renamer_source_dir}" ! -group "${couchpotato_group}" -exec chgrp "${couchpotato_group}" {} \;
   fi
}

LaunchCouchPotato (){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    ***** Configuration of CouchPotato container launch environment complete *****"
   if [ -z "${1}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Starting CouchPotato as ${stack_user}"
      exec "$(which su)" -p "${stack_user}" -c "$(which python) ${app_base_dir}/CouchPotato.py --data_dir ${config_dir} --config_file ${config_dir}/couchpotato.ini --console_log $(cat "${config_dir}/enable_debugging")"
   else
      exec "$@"
   fi
}

##### Script #####
InitialiseVariables
CreateGroup
CreateUser
FirstRun
EnableSSL
Configure
Kodi
SABnzbd
Deluge
Prowl
Telegram
OMGWTFNZBs
SetOwnerAndGroup
LaunchCouchPotato