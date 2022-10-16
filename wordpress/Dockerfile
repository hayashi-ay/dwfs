FROM debian:bullseye-slim

RUN set -x \
    && apt-get update && apt-get install -y --no-install-recommends \
    php-fpm \
    # install PHP extensions for hosting WordPress
    # https://make.wordpress.org/hosting/handbook/handbook/server-environment/#php-extensions
    php-mysqli \
    # for connecting to mariadb
    mariadb-client \
    # for installing wp-cli
    curl \
    ca-certificates \
    # remove APT lists
    && rm -rf /var/lib/apt/lists/* \
    # used for temporary data(socket and lock files) at runtime
    && mkdir /run/php

# pass environment value to Dockerfile
ARG WP_PATH
ENV WP_PATH=${WP_PATH}

# install WP-CLI
RUN set -ux \
    && curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp \
    # download WordPress core files
    && mkdir -p "${WP_PATH}" \
    && wp core download --allow-root --path="${WP_PATH}"

COPY conf /etc/php/7.4/fpm/pool.d/www.conf
COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 9000
CMD ["php-fpm7.4", "-F"]
