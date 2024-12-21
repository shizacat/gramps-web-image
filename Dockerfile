# Build API wheel package with patches
# ----------------------------------------------------------------------------
FROM python:3.12-slim as builder

ARG GRAMPS_WEB_API_GIT_REPO=https://github.com/gramps-project/gramps-web-api.git
ARG GRAMPS_WEB_API_VERSION=v2.6.0
# gramps_webapi-2.6.0-py3-none-any.whl

RUN apt-get update && \
    apt-get install -y git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY patches /app/patches
RUN git clone $GRAMPS_WEB_API_GIT_REPO && \
    cd gramps-web-api && \
    git checkout $GRAMPS_WEB_API_VERSION && \
    # apply patches
    patch -p1 < /app/patches/gramps_web_api_0001_media_import.patch && \
    # build wheel package
    pip install --upgrade pip && \
    pip install wheel build && \
    python -m build --wheel && \
    ls -la /app/gramps-web-api/dist

# Create alembic archive. Skip alembic.ini
RUN cd /app/gramps-web-api && \
    tar -czf /app/alembic.tar.gz alembic_users

# Build frontend, static
# ----------------------------------------------------------------------------
# FROM node:16.19.1-alpine3.17 as frontend
# ARG GRAMPS_FRONTEND_GIT_REPO=https://github.com/gramps-project/gramps-web.git
# ARG GRAMPS_FRONTEND_VERSION=v24.12.1

# RUN apk add git

# WORKDIR /app

# RUN git clone $GRAMPS_FRONTEND_GIT_REPO && \
#     cd gramps-web && \
#     git checkout $GRAMPS_FRONTEND_VERSION && \
#     npm install && \
#     npm run build

# Main image
# ----------------------------------------------------------------------------
FROM debian:bookworm

ARG GRAMPS_WEB_API_VERSION=2.6.0

ENV DEBIAN_FRONTEND=noninteractive
ENV GRAMPS_VERSION=52
ENV GRAMPS_API_CONFIG=/app/config/config.cfg
# limit pytorch to 1 thread
ENV OMP_NUM_THREADS=1
# set config options
ENV GRAMPSWEB_MEDIA_BASE_DIR=/app/media
ENV GRAMPSWEB_STATIC_PATH=/static
ENV GRAMPSWEB_USER_DB_URI=sqlite:////app/users/users.sqlite
ENV GRAMPSWEB_SEARCH_INDEX_DB_URI=sqlite:////app/indexdir/search_index.db
ENV GRAMPSWEB_THUMBNAIL_CACHE_CONFIG__CACHE_DIR=/app/thumbnail_cache
ENV GRAMPSWEB_REPORT_DIR=/app/cache/reports
ENV GRAMPSWEB_EXPORT_DIR=/app/cache/export
# alembic config
ENV ALEMBIC_CONFIG=/alembic/alembic.ini

WORKDIR /app

# install poppler (needed for PDF thumbnails)
# ffmpeg (needed for video thumbnails)
# postgresql client (needed for PostgreSQL backend)
RUN apt-get update \
    && apt-get install -y \
        locales gettext wget unzip \
        appstream pkg-config libcairo2-dev \
        gir1.2-gtk-3.0 libgirepository1.0-dev libicu-dev \
        graphviz gir1.2-gexiv2-0.10 gir1.2-osmgpsmap-1.0 \
        python3-pip python3-pil \
        poppler-utils ffmpeg libavcodec-extra \
        libpq-dev postgresql-client postgresql-client-common python3-psycopg2 \
        libgl1-mesa-dev libgtk2.0-dev libatlas-base-dev \
        tesseract-ocr tesseract-ocr-all \
        libopenblas-dev cmake \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# set locale
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANGUAGE en_US.utf8
ENV LANG en_US.utf8
ENV LC_ALL en_US.utf8

# create directories
RUN mkdir -p /root/.gramps/gramps$GRAMPS_VERSION/plugins

# install PostgreSQL addon
RUN wget https://github.com/gramps-project/addons/archive/refs/heads/master.zip \
    && unzip -p master.zip addons-master/gramps$GRAMPS_VERSION/download/PostgreSQL.addon.tgz | \
    tar -xvz -C /root/.gramps/gramps$GRAMPS_VERSION/plugins \
    && unzip -p master.zip addons-master/gramps$GRAMPS_VERSION/download/SharedPostgreSQL.addon.tgz | \
    tar -xvz -C /root/.gramps/gramps$GRAMPS_VERSION/plugins \
    && unzip -p master.zip addons-master/gramps$GRAMPS_VERSION/download/FilterRules.addon.tgz | \
    tar -xvz -C /root/.gramps/gramps$GRAMPS_VERSION/plugins \
    && rm master.zip

# install gunicorn
RUN python3 -m pip install \
        --break-system-packages \
        --no-cache-dir \
        --extra-index-url https://www.piwheels.org/simple \
        gunicorn

# Disable[size]
# Install PyTorch based on architecture
# RUN ARCH=$(uname -m) && \
#     if [ "$ARCH" != "armv7l" ]; then \
#         # PyTorch and opencv not supported on armv7l
#         python3 -m pip install \
#             --break-system-packages \
#             --no-cache-dir \
#             --index-url https://download.pytorch.org/whl/cpu \
#             torch; \
#         python3 -m pip install \
#             --break-system-packages \
#             --no-cache-dir \
#             --extra-index-url https://www.piwheels.org/simple \
#             opencv-python opencv-contrib-python; \
#     fi

# copy package source from builder and install
COPY --from=builder /app/gramps-web-api/dist/gramps_webapi-${GRAMPS_WEB_API_VERSION}-py3-none-any.whl /tmp/pkg/
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "armv7l" ]; then \
        python3 -m pip install \
            --break-system-packages \
            --no-cache-dir /tmp/pkg/gramps_webapi-${GRAMPS_WEB_API_VERSION}-py3-none-any.whl; \
    else \
        python3 -m pip install --break-system-packages \
            --no-cache-dir \
            --extra-index-url https://www.piwheels.org/simple \
            /tmp/pkg/gramps_webapi-${GRAMPS_WEB_API_VERSION}-py3-none-any.whl[ai]; \
    fi \
    && rm -rf /tmp/pkg

# copy alembic archive from builder
COPY --from=builder /app/alembic.tar.gz /alembic/
COPY alembic.ini /alembic/
RUN tar -xzf /alembic/alembic.tar.gz -C /alembic

# copy frontend build, from ghcr.io/gramps-project/grampsjs:v24.12.1
ARG GRAMPS_FRONTEND_VERSION=v24.12.1
COPY --from=ghcr.io/gramps-project/grampsjs:${GRAMPS_FRONTEND_VERSION} /usr/share/nginx/html /static
# COPY --from=frontend /app/gramps-web/build /static

# Disable[size]
# download and cache sentence transformer model
# RUN ARCH=$(uname -m) && \
#     if [ "$ARCH" != "armv7l" ]; then \
#         python3 -c "from sentence_transformers import SentenceTransformer; \
# model = SentenceTransformer('sentence-transformers/distiluse-base-multilingual-cased-v2')"; \
#     fi

EXPOSE 5000

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD gunicorn -w ${GUNICORN_NUM_WORKERS:-8} \
    -b 0.0.0.0:5000 \
    gramps_webapi.wsgi:app \
    --timeout ${GUNICORN_TIMEOUT:-120} \
    --limit-request-line 8190
