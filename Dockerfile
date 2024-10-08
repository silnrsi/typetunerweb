# syntax=docker/dockerfile:1
FROM alpine
LABEL org.opencontainers.image.source=https://github.com/silnrsi/typetunerweb
LABEL org.opencontainers.image.description="TypeTunerWeb for customising default OpenType features on selected fonts"
LABEL org.opencontainers.image.licenses=MIT
COPY --link web/server/fonts?go.cgi /var/www/typetunerweb/web/server/
COPY --link web/server/TypeTuner/typetuner.pl /var/www/typetunerweb/web/server/TypeTuner/
VOLUME /tunable-fonts
EXPOSE 9000
ENTRYPOINT exec su fcgiwrap -s /bin/sh -c 'fcgiwrap -s tcp:0.0.0.0:9000'
RUN --mount=type=cache,target=/var/cache/apk,sharing=private \
    --mount=type=cache,target=/var/lib/apk,sharing=private \
<<EOT
    apk upgrade
    apk --no-cache add fcgiwrap \
        perl-font-ttf perl-xml-parser perl-cgi zip
    mkdir /var/log/ttw
    ln -s /tunable-fonts /var/www/typetunerweb/web/server/TypeTuner/
    ln -s /var/www/typetunerweb/web/server /var/www/ttw
    ln -s /dev/stderr /var/log/ttw/fonts2go.log
    ln -s /dev/stderr /var/log/ttw/fonts3go.log
EOT
