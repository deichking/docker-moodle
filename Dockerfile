# Docker-Moodle
# Dockerfile for moodle instance. more dockerish version of https://github.com/sergiogomez/docker-moodle
# Forked from Jade Auer's docker version. https://github.com/jda/docker-moodle
# Forked from Jonathan Hardison's docker version. https://github.com/jmhardison/docker-moodle
FROM ubuntu:20.04
LABEL maintainer="Deichking <info@deichking.de>"

VOLUME ["/var/moodledata"]
EXPOSE 80 443
COPY moodle-config.php /var/www/html/config.php

# Let the container know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

# Database info and other connection information derrived from env variables. See readme.
    # Set ENV Variables externally Moodle_URL should be overridden.
ENV MOODLE_URL="http://127.0.0.1" \
    # Enable when using external SSL reverse proxy
    # Default: false
    SSL_PROXY="false" \
    DB_TYPE="mariadb" \
    DB_HOST="localhost" \
    DB_PORT="" \
    DB_PERSIST="false" \
    DB_NAME="moodle" \
    DB_USER="moodle" \
    DB_PASSWORD="mySuperSecretP@ssw0rd" \
    TBL_PREFIX="mdl_" \
    # PHP settings for file upload
    POST_MAX_SIZE="256M" \
    UPLOAD_MAX_FILESIZE="256M" \
    MAX_EXECUTION_TIME="600"

COPY ./foreground.sh /etc/apache2/foreground.sh

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install mysql-client pwgen python-setuptools curl git unzip apache2 php \
                       php-gd libapache2-mod-php postfix wget supervisor php-pgsql curl libcurl4 \
                       libcurl3-dev php-curl php-xmlrpc php-intl php-mysql git-core php-xml php-mbstring php-zip php-soap cron php-ldap \
                       locales && \
    locale-gen en_US.UTF-8 && \
    locale-gen de_DE.UTF-8 && \
    cd /tmp && \
    git clone -b MOODLE_311_STABLE git://git.moodle.org/moodle.git --depth=1 && \
    mv /tmp/moodle/* /var/www/html/ && \
    rm /var/www/html/index.html && \
    chown -R www-data:www-data /var/www/html && \
    chmod +x /etc/apache2/foreground.sh

# cron doesn't run in containers, so it has to be configured external
# COPY moodlecron /etc/cron.d/moodlecron
# RUN chmod 0644 /etc/cron.d/moodlecron
# RUN service cron start

# Enable SSL, moodle requires it
RUN a2enmod ssl && a2ensite default-ssl  #if using proxy dont need actually secure connection

# Cleanup, this is ran to reduce the resulting size of the image.
RUN apt-get clean autoclean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/lib/dpkg/* /var/lib/cache/* /var/lib/log/*

ENTRYPOINT ["/etc/apache2/foreground.sh"]
