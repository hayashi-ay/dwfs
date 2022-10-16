FROM debian:bullseye-slim

RUN set -x \
    && apt-get update && apt-get install -y --no-install-recommends \
    mariadb-server \
    # remove APT lists
    && rm -rf /var/lib/apt/lists/*

# create /run/mysqld (used for socket and lock files) with appropriate ownership.
RUN set -x \
    && mkdir /run/mysqld \
    && chown -R mysql:mysql /run/mysqld \
    # for init purpose.
    && mkdir /docker-entrypoint-initdb.d \
    # forward error logs to docker log collector.
    && ln -sf /dev/stderr /var/log/mysql/error.log

VOLUME /var/lib/mysql

COPY conf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY init/* /docker-entrypoint-initdb.d/
COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 3306
CMD ["mysqld"]
