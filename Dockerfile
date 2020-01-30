FROM alpine:latest
MAINTAINER boredazfcuk
ARG app_repo="CouchPotato/CouchPotatoServer"
ARG build_dependencies="gcc python2-dev py2-pip musl-dev libffi-dev openssl-dev"
ARG python_dependencies="pyopenssl lxml"
ARG app_dependencies="git python2 libxml2-dev libxslt-dev tzdata openssl unrar"
ARG patch_dir="${app_base_dir}/patches"
ENV app_base_dir="/CouchPotatoServer" \
   config_dir="/config"

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD STARTED *****" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Create application base directory" && \
   mkdir -p "${app_base_dir}" "${patch_dir}" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install build dependencies" && \
   apk add --no-cache --no-progress --virtual=build-deps ${build_dependencies} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install application dependencies" && \
   apk add --no-cache --no-progress ${app_dependencies} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install ${app_repo}" && \
   git clone -b develop "https://github.com/${app_repo}.git" "${app_base_dir}" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install Python dependencies" && \
   cd "${app_base_dir}" && \
   pip install --upgrade pip && \
   pip install ${python_dependencies} && \
#echo "$(date '+%d/%m/%Y - %H:%M:%S') | Download CouchPotato pull request patches" && \
#   wget --quiet https://github.com/CouchPotato/CouchPotatoServer/pull/7306.diff --output-document "${patch_dir}/couchpotatoserver_pr7306.diff" && \
#echo "$(date '+%d/%m/%Y - %H:%M:%S') | Apply fix for utf8 file names" && \
#   /usr/libexec/git-core/git-apply "${patch_dir}/couchpotatoserver_pr7306.diff" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Clean up" && \
      apk del --purge --no-progress build-deps

COPY start-couchpotato.sh /usr/local/bin/start-couchpotato.sh
COPY healthcheck.sh /usr/local/bin/healthcheck.sh

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | Set permissions on launch script" && \
   chmod +x /usr/local/bin/start-couchpotato.sh /usr/local/bin/healthcheck.sh && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD COMPLETE *****"

HEALTHCHECK --start-period=10s --interval=1m --timeout=10s \
  CMD /usr/local/bin/healthcheck.sh

VOLUME "${config_dir}"

WORKDIR "${app_base_dir}"

CMD /usr/local/bin/start-couchpotato.sh