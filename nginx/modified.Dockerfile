FROM nginx:alpine

LABEL maintainer="Mahmoud Zalt <mahmoud@zalt.me>"

#!##########################################################################
#! Modified

# Change the build context
ARG CUSTOM_CONTEXT='./'

ARG NGINX_SITES_PATH=sites
ARG NGINX_SSL_PATH=ssl
COPY ${CUSTOM_CONTEXT}${NGINX_SITES_PATH} /etc/nginx/sites-available
COPY ${CUSTOM_CONTEXT}${NGINX_SSL_PATH} /etc/nginx/ssl

#!##########################################################################

#! Modified
COPY ${CUSTOM_CONTEXT}nginx.conf /etc/nginx/

# If you're in China, or you need to change sources, will be set CHANGE_SOURCE to true in .env.

ARG CHANGE_SOURCE=false
RUN if [ ${CHANGE_SOURCE} = true ]; then \
    # Change application source from dl-cdn.alpinelinux.org to aliyun source
    sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/' /etc/apk/repositories \
;fi

RUN apk update \
    && apk upgrade \
    && apk --update add logrotate \
    && apk add --no-cache openssl \
    && apk add --no-cache bash

RUN apk add --no-cache curl

RUN set -x ; \
    addgroup -g 82 -S www-data ; \
    adduser -u 82 -D -S -G www-data www-data && exit 0 ; exit 1

ARG PHP_UPSTREAM_CONTAINER=php-fpm
ARG PHP_UPSTREAM_PORT=9000

# Create 'messages' file used from 'logrotate'
RUN touch /var/log/messages

# Copy 'logrotate' config file
#! Modified
COPY ${CUSTOM_CONTEXT}logrotate/nginx /etc/logrotate.d/

# Set upstream conf and remove the default conf
RUN echo "upstream php-upstream { server ${PHP_UPSTREAM_CONTAINER}:${PHP_UPSTREAM_PORT}; }" > /etc/nginx/conf.d/upstream.conf \
    && rm /etc/nginx/conf.d/default.conf

#! Modified
ADD ${CUSTOM_CONTEXT}./startup.sh /opt/startup.sh
RUN sed -i 's/\r//g' /opt/startup.sh
CMD ["/bin/bash", "/opt/startup.sh"]

#!##########################################################################
#! Modified

ARG APP_CODE_PATH_HOST=./
ARG APP_CODE_PATH_CONTAINER=/var/www
COPY ${CUSTOM_CONTEXT}${APP_CODE_PATH_HOST} ${APP_CODE_PATH_CONTAINER}

#!##########################################################################

EXPOSE 80 81 443
