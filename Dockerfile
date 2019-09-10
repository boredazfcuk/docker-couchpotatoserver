FROM alpine:latest
MAINTAINER boredazfcuk
ENV APPBASE="/CouchPotatoServer" \
   REPO="CouchPotato/CouchPotatoServer" \
   CONFIGDIR="/config" \
   APPDEPENDENCIES="git python py2-lxml py-openssl libxslt-dev tzdata"

COPY start-couchpotato.sh /usr/local/bin/start-couchpotato.sh

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD STARTED *****" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Create application base directory" && \
   mkdir -p "${APPBASE}" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install application dependencies" && \
   apk add --no-cache --no-progress ${APPDEPENDENCIES} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install ${REPO}" && \
   git clone -b master "https://github.com/${REPO}.git" "${APPBASE}" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Set permissions on launch script" && \
   chmod +x /usr/local/bin/start-couchpotato.sh && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD COMPLETE *****"

HEALTHCHECK --start-period=10s --interval=1m --timeout=10s \
  CMD wget --quiet --tries=1 --spider "http://${HOSTNAME}:5050/couchpotato" || exit 1

VOLUME "${CONFIGDIR}"
WORKDIR "${APPBASE}"

CMD /usr/local/bin/start-couchpotato.sh