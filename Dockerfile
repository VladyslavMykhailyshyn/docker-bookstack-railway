# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-alpine-nginx:3.21

# set version label
ARG BUILD_DATE
ARG VERSION
ARG BOOKSTACK_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thespad"

ENV S6_STAGE2_HOOK="/init-hook"

RUN \
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
    fontconfig \
    mariadb-client \
    memcached \
    php83-dom \
    php83-exif \
    php83-gd \
    php83-ldap \
    php83-mysqlnd \
    php83-pdo_mysql \
    php83-pecl-memcached \
    php83-tokenizer \
    qt5-qtbase \
    ttf-freefont && \
  echo "**** configure php-fpm to pass env vars ****" && \
  sed -E -i 's/^;?clear_env ?=.*$/clear_env = no/g' /etc/php83/php-fpm.d/www.conf && \
  grep -qxF 'clear_env = no' /etc/php83/php-fpm.d/www.conf || echo 'clear_env = no' >> /etc/php83/php-fpm.d/www.conf && \
  echo "env[PATH] = /usr/local/bin:/usr/bin:/bin" >> /etc/php83/php-fpm.conf && \
  echo "**** fetch bookstack ****" && \
  mkdir -p\
    /app/www && \
  if [ -z ${BOOKSTACK_RELEASE+x} ]; then \
    BOOKSTACK_RELEASE=$(curl -sX GET "https://api.github.com/repos/bookstackapp/bookstack/releases/latest" \
    | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  curl -o \
    /tmp/bookstack.tar.gz -L \
    "https://github.com/BookStackApp/BookStack/archive/${BOOKSTACK_RELEASE}.tar.gz" && \
  tar xf \
    /tmp/bookstack.tar.gz -C \
    /app/www/ --strip-components=1 && \
  echo "**** install composer dependencies ****" && \
  composer install -d /app/www/ && \
  printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
  echo "**** create symlinks ****" && \
  rm -rf /app/www/themes && ln -s /config/www/themes /app/www/themes && \
  rm -rf /app/www/storage/uploads/files && ln -s /config/www/files /app/www/storage/uploads/files && \
  rm -rf /app/www/storage/uploads/images && ln -s /config/www/images /app/www/storage/uploads/images && \
  rm -rf /app/www/public/uploads && ln -s /config/www/uploads /app/www/public/uploads && \
  rm -rf /app/www/storage/backup && ln -s /config/backups /app/www/storage/backups && \
  rm -rf /app/www/storage/framework/cache && ln -s /config/www/framework/cache /app/www/storage/framework/cache && \
  rm -rf /app/www/storage/framework/sessions && ln -s /config/www/framework/sessions /app/www/storage/framework/sessions && \
  rm -rf /app/www/storage/framework/views && ln -s /config/www/framework/views /app/www/storage/framework/views && \
  rm -rf /app/www/storage/logs/laravel.log && ln -s /config/log/bookstack/laravel.log /app/www/storage/logs/laravel.log && \
  rm -rf /app/www/.env && ln -s /config/www/.env /app/www/.env && \
  echo "**** cleanup ****" && \
  rm -rf \
    /tmp/* \
    $HOME/.cache \
    $HOME/.composer

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 80 443
VOLUME /config
