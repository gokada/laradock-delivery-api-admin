FROM nginx:alpine

LABEL maintainer="Mahmoud Zalt <mahmoud@zalt.me>"

COPY nginx.conf /etc/nginx/

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

# Create 'messages' file used from 'logrotate'
RUN touch /var/log/messages

# Copy 'logrotate' config file
COPY logrotate/nginx /etc/logrotate.d/

ADD ./startup.sh /opt/startup.sh
RUN sed -i 's/\r//g' /opt/startup.sh
CMD ["/bin/bash", "/opt/startup.sh"]

#!##########################################################################
#! Modified
# Set the deployment context [cloud | local]
ARG DEPLOYMENT_CONTEXT=local

# Copy the config files to a temporary directory
ARG NGINX_SITES_PATH=sites
ARG NGINX_SSL_PATH=ssl
COPY ${NGINX_SITES_PATH} /tmp-build-cache/sites-available
COPY ${NGINX_SSL_PATH} /tmp-build-cache/ssl

# During cloud deployment move the config files to their appropriate directories
RUN if [ "$DEPLOYMENT_CONTEXT" = "cloud" ]; then \
      cp -a /tmp-build-cache/sites-available/. /etc/nginx/sites-available/; \
      cp -a /tmp-build-cache/ssl/. /etc/nginx/ssl; \
    fi

# Remove the temporary directory
RUN rm -R /tmp-build-cache
#!##########################################################################
