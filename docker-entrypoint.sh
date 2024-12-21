#!/bin/sh
set -e

# Make directries
if [ ! -d /app/config ]; then
    mkdir /app/config
    touch /app/config/config.cfg
fi
if [ ! -d /app/static ]; then
    mkdir /app/static
    touch /app/static/index.html
fi
[ ! -d /app/db ] && mkdir /app/db
[ ! -d /app/media ] && mkdir /app/media
[ ! -d /app/indexdir ] && mkdir /app/indexdir
[ ! -d /app/users ] && mkdir /app/users
[ ! -d /app/thumbnail_cache ] && mkdir /app/thumbnail_cache
[ ! -d /app/cache ] && mkdir /app/cache
[ ! -d /app/cache/reports ] && mkdir /app/cache/reports
[ ! -d /app/cache/export ] && mkdir /app/cache/export
[ ! -d /app/tmp ] && mkdir /app/tmp
[ ! -d /app/persist ] && mkdir /app/persist

# use the secret key if none is set (will be overridden by config file if present)
if [ -z "$GRAMPSWEB_SECRET_KEY" ]
then
    # create random flask secret key
    if [ ! -s /app/secret/secret ]
    then
        mkdir -p /app/secret
        python3 -c "import secrets;print(secrets.token_urlsafe(32))"  | tr -d "\n" > /app/secret/secret
    fi
    export GRAMPSWEB_SECRET_KEY=$(cat /app/secret/secret)
fi

# Run migrations for user database, if any
python3 -m gramps_webapi --config /app/config/config.cfg user migrate
cd /app/

exec "$@"
