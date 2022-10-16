FROM debian:bullseye-slim

RUN set -x \
    && apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    # remove APT lists
    && rm -rf /var/lib/apt/lists/* \
    # forward request and error logs to docker log collector.
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# sites-available/default is aliased to sites-enabled/default
COPY conf /etc/nginx/sites-available/default
COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 443
# run nginx in the forground, so that Docker can track the process properly.
# https://nginx.org/en/docs/ngx_core_module.html#daemon
CMD ["nginx", "-g", "daemon off;"]
