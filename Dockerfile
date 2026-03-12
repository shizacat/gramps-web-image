# Build API wheel package with patches
# ----------------------------------------------------------------------------
FROM python:3.12-slim as builder

ARG GRAMPS_WEB_API_GIT_REPO=https://github.com/gramps-project/gramps-web-api.git
ARG GRAMPS_WEB_API_VERSION=v3.7.1.1

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
    patch -p1 < /app/patches/gramps_web_api_0002_pygobject_version.patch && \
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

ARG GRAMPS_WEB_API_VERSION=3.7.1.1

ENV DEBIAN_FRONTEND=noninteractive
ENV GRAMPS_VERSION=60
ENV GRAMPS_API_CONFIG=/app/config/config.cfg
# limit pytorch to 1 thread
ENV OMP_NUM_THREADS=1
# set config options
ENV GRAMPSWEB_USER_DB_URI=sqlite:////app/users/users.sqlite
ENV GRAMPSWEB_MEDIA_BASE_DIR=/app/media
ENV GRAMPSWEB_SEARCH_INDEX_DB_URI=sqlite:////app/indexdir/search_index.db
# ENV GRAMPSWEB_STATIC_PATH=/app/static
ENV GRAMPSWEB_STATIC_PATH=/static
ENV GRAMPSWEB_THUMBNAIL_CACHE_CONFIG__CACHE_DIR=/app/thumbnail_cache
ENV GRAMPSWEB_REQUEST_CACHE_CONFIG__CACHE_DIR=/app/cache/request_cache
ENV GRAMPSWEB_PERSISTENT_CACHE_CONFIG__CACHE_DIR=/app/cache/persistent_cache
ENV GRAMPSWEB_REPORT_DIR=/app/cache/reports
ENV GRAMPSWEB_EXPORT_DIR=/app/cache/export
ENV GRAMPSHOME=/root
ENV GRAMPS_DATABASE_PATH=/root/.gramps/grampsdb

# alembic config
ENV ALEMBIC_CONFIG=/alembic/alembic.ini

ENV PYTHONPATH="/usr/lib/python3/dist-packages"

WORKDIR /app

# install poppler (needed for PDF thumbnails)
# ffmpeg (needed for video thumbnails)
# postgresql client (needed for PostgreSQL backend)
RUN apt-get update && apt-get install -y \
        appstream pkg-config libcairo2-dev \
        gir1.2-gtk-3.0 libgirepository1.0-dev libicu-dev \
        graphviz gir1.2-gexiv2-0.10 gir1.2-osmgpsmap-1.0 \
        locales gettext wget python3-pip python3-pil \
        poppler-utils ffmpeg libavcodec-extra \
        unzip \
        libpq-dev postgresql-client postgresql-client-common python3-psycopg2 \
        libgl1-mesa-dev libgtk2.0-dev libatlas-base-dev \
        tesseract-ocr \
        # tesseract-ocr-ara \
        # tesseract-ocr-bul \
        # tesseract-ocr-bre \
        # tesseract-ocr-cat \
        # tesseract-ocr-ces \
        # tesseract-ocr-dan \
        # tesseract-ocr-deu \
        # tesseract-ocr-ell \
        tesseract-ocr-eng \
        # tesseract-ocr-epo \
        # tesseract-ocr-spa \
        # tesseract-ocr-fin \
        # tesseract-ocr-fra \
        # tesseract-ocr-gle \
        # tesseract-ocr-heb \
        # tesseract-ocr-hrv \
        # tesseract-ocr-hun \
        # tesseract-ocr-isl \
        # tesseract-ocr-ind \
        # tesseract-ocr-ita \
        # tesseract-ocr-jpn \
        # tesseract-ocr-kor \
        # tesseract-ocr-lit \
        # tesseract-ocr-lav \
        # tesseract-ocr-mkd \
        # tesseract-ocr-nor \
        # tesseract-ocr-nld \
        # tesseract-ocr-pol \
        # tesseract-ocr-por \
        # tesseract-ocr-ron \
        tesseract-ocr-rus \
        # tesseract-ocr-slk \
        # tesseract-ocr-slv \
        # tesseract-ocr-sqi \
        # tesseract-ocr-srp \
        # tesseract-ocr-swe \
        # tesseract-ocr-tam \
        # tesseract-ocr-tur \
        # tesseract-ocr-ukr \
        # tesseract-ocr-vie \
        # tesseract-ocr-chi-sim \
        # tesseract-ocr-chi-tra \
        libopenblas-dev cmake \
        && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# set locale
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANGUAGE en_US.utf8
ENV LANG en_US.utf8
ENV LC_ALL en_US.utf8

# install wheel first to enable binary packages for all pip installs
RUN python3 -m pip install --break-system-packages --no-cache-dir wheel

# install gunicorn
RUN python3 -m pip install --break-system-packages --no-cache-dir \
    gunicorn

# Install PyICU (slow to compile on ARM, so pre-install in base image)
RUN python3 -m pip install --break-system-packages --no-cache-dir \
    PyICU

# Install PyTorch and opencv
# RUN python3 -m pip install --break-system-packages --no-cache-dir --index-url https://download.pytorch.org/whl/cpu torch
# RUN python3 -m pip install --break-system-packages --no-cache-dir \
#     opencv-python opencv-contrib-python

# Install AI dependencies
# RUN python3 -m pip install --break-system-packages --no-cache-dir \
#     'sentence-transformers>=4.1.0' \
#     'accelerate' \
#     'pydantic-ai[openai]>=1.0.0,<2.0.0'

# download and cache sentence transformer model
# RUN python3 -c "from sentence_transformers import SentenceTransformer; \
# model = SentenceTransformer('sentence-transformers/distiluse-base-multilingual-cased-v2');"

# install Gramps addons
# __ create directories
# __ TODO: The '/app' directory will be created by the docker-entrypoint.sh script.
RUN mkdir -p /root/gramps/gramps$GRAMPS_VERSION/plugins && \
    wget https://github.com/gramps-project/addons/archive/refs/heads/master.zip && \
    for addon in PostgreSQL SharedPostgreSQL FilterRules JSON; do \
        unzip -p master.zip addons-master/gramps$GRAMPS_VERSION/download/$addon.addon.tgz | \
        tar -xvz -C /root/gramps/gramps$GRAMPS_VERSION/plugins; \
    done && \
    rm master.zip

# Pin NumPy < 2.0 to avoid X86_V2 baseline requirement on older CPUs
RUN python3 -m pip install \
        --break-system-packages \
        --no-cache-dir \
        "numpy<2"

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
            /tmp/pkg/gramps_webapi-${GRAMPS_WEB_API_VERSION}-py3-none-any.whl; \
    fi \
    && rm -rf /tmp/pkg

# copy alembic archive from builder
COPY --from=builder /app/alembic.tar.gz /alembic/
COPY alembic.ini /alembic/
RUN tar -xzf /alembic/alembic.tar.gz -C /alembic

# copy frontend build, from ghcr.io/gramps-project/grampsjs:v24.12.1
# ARG GRAMPS_FRONTEND_VERSION=v24.12.1
COPY --from=ghcr.io/gramps-project/grampsjs:v26.2.0 /usr/share/nginx/html /static
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
