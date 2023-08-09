FROM nginx:alpine

LABEL maintainer="Mahmoud Zalt <mahmoud@zalt.me>"

#!##########################################################################
#! Modified
# Change the build context
ARG CUSTOM_CONTEXT='./'
ARG PHP_UPSTREAM_CONTAINER_CLOUD=127.0.0.1
ARG PHP_UPSTREAM_PORT_CLOUD=9000
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

#!##########################################################################
#! Modified
# Set upstream conf and remove the default conf
RUN if [ "$DEPLOYMENT_CONTEXT" = "cloud" ]; then \
        echo "upstream php-upstream { server ${PHP_UPSTREAM_CONTAINER_CLOUD}:${PHP_UPSTREAM_PORT_CLOUD}; }" > /etc/nginx/conf.d/upstream.conf; \
    else echo "upstream php-upstream { server ${PHP_UPSTREAM_CONTAINER}:${PHP_UPSTREAM_PORT}; }" > /etc/nginx/conf.d/upstream.conf; \
    fi
#!##########################################################################

#! Modified
ADD ${CUSTOM_CONTEXT}./startup.sh /opt/startup.sh
RUN sed -i 's/\r//g' /opt/startup.sh
CMD ["/bin/bash", "/opt/startup.sh"]

#!##########################################################################
#! Modified
# Set the deployment context [cloud | local]
ARG DEPLOYMENT_CONTEXT=local

# Copy the config files to a temporary directory
ARG NGINX_SITES_PATH=sites
ARG NGINX_SSL_PATH=ssl
COPY ${CUSTOM_CONTEXT}${NGINX_SITES_PATH} /tmp-build-cache/sites-available
COPY ${CUSTOM_CONTEXT}${NGINX_SSL_PATH} /tmp-build-cache/ssl

# During cloud deployment move the config files to their appropriate directories
RUN if [ "$DEPLOYMENT_CONTEXT" = "cloud" ]; then \
      cp -a /tmp-build-cache/sites-available/. /etc/nginx/sites-available/; \
      cp -a /tmp-build-cache/ssl/. /etc/nginx/ssl; \
    fi

# Copy the codebase to a temporary directory
ARG APP_CODE_PATH_HOST=./
ARG APP_CODE_PATH_CONTAINER=/var/www
COPY ${CUSTOM_CONTEXT}${APP_CODE_PATH_HOST} /tmp-build-cache/codebase

# During cloud deployment move the codebase to the appropriate directory
RUN if [ "$DEPLOYMENT_CONTEXT" = "cloud" ]; then \
      cp -a /tmp-build-cache/codebase/. ${APP_CODE_PATH_CONTAINER}/; \
    fi

# Remove the temporary directory
RUN rm -R /tmp-build-cache
#!##########################################################################

EXPOSE 80 81 443
