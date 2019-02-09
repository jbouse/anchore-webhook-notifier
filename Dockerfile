FROM nginx:alpine

LABEL maintainer "Jeremy T. Bouse <Jeremy.Bouse@UnderGrid.net"

RUN apk add --no-cache --update curl py-pip nginx-mod-http-lua lua5.1-rapidjson \
    && pip install --no-cache-dir --no-color awscli \
    && rm -rf /var/cache/apk/*

HEALTHCHECK --start-period=20s --interval=5m CMD curl -f localhost/ || exit 1

COPY nginx /etc/nginx
COPY lua /var/lib/nginx
