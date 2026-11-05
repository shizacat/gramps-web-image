# Build API wheel package with patches
# ----------------------------------------------------------------------------
FROM python:3.13-slim-trixie AS builder

ARG GRAMPS_WEB_API_GIT_REPO=https://github.com/gramps-project/gramps-web-api.git
ARG GRAMPS_WEB_API_VERSION=v3.25.1

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

# Build wheels for the Python packages that have no binary wheels,
# so that the main image needs no compiler or development headers
# ----------------------------------------------------------------------------
FROM debian:trixie AS wheels

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential pkg-config python3-dev python3-venv \
        libcairo2-dev libgirepository1.0-dev libicu-dev \
    && rm -rf /var/lib/apt/lists/*

# keep the PyGObject version in sync with patches/gramps_web_api_0002_pygobject_version.patch
RUN python3 -m venv /venv \
    && /venv/bin/pip wheel --no-cache-dir --wheel-dir /wheels 'PyGObject<3.50.0' pycairo PyICU

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
FROM debian:trixie

# The name of library from _version.py
ARG GRAMPS_WEB_API_VERSION=3.25.1

ENV DEBIAN_FRONTEND=noninteractive
ENV GRAMPS_VERSION=60
ENV GRAMPS_API_CONFIG=/app/config/config.cfg
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

WORKDIR /app

# install poppler (needed for PDF thumbnails)
# ffmpeg (needed for video thumbnails)
# postgresql client (needed for PostgreSQL backend)
# Noto fonts (needed to render non-Latin scripts in generated reports -
# without them, Pango has no glyphs and PDF output is garbled)
# libcairo, libgirepository and libicu are needed by the wheels from the wheels stage
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        fonts-dejavu-core fonts-noto-core \
        # fonts-noto-cjk: large, only for Chinese/Japanese/Korean
        # fonts-noto-cjk \
        libcairo2 libcairo-gobject2 libgirepository-1.0-1 libicu76 \
        gir1.2-gtk-3.0 gir1.2-pango-1.0 \
        graphviz gir1.2-gexiv2-0.10 gir1.2-osmgpsmap-1.0 \
        locales gettext wget python3-venv \
        poppler-utils poppler-data ffmpeg libavcodec-extra \
        unzip \
        postgresql-client postgresql-client-common \
        tesseract-ocr \
        tesseract-ocr-osd \
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
        # NumPy from Debian: PyPI wheels 2.x require X86_V2 (old CPUs),
        # and numpy<2 has no wheels for Python 3.13
        python3-numpy \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# set locale
ENV LANGUAGE=en_US.utf8
ENV LANG=en_US.utf8
ENV LC_ALL=en_US.utf8

# limit OpenMP and BLAS (NumPy, OpenCV) to 1 thread
ENV OMP_NUM_THREADS=1

# Use a venv so pip can manage packages without conflicting with Debian-installed ones
RUN python3 -m venv /venv --system-site-packages
ENV PATH="/venv/bin:$PATH"

# install wheel first to enable binary packages for all pip installs
RUN pip install --no-cache-dir wheel

# install gunicorn
RUN pip install --no-cache-dir gunicorn

# install Pillow from PyPI (PyPI wheel includes AVIF support, unlike the apt package)
RUN pip install --no-cache-dir Pillow

# Install the wheels compiled in the wheels stage
RUN --mount=type=bind,from=wheels,source=/wheels,target=/wheels \
    pip install --no-cache-dir /wheels/*.whl

# Install opencv
# keep in sync with the "face" extra in gramps-web-api pyproject.toml
RUN pip install --no-cache-dir "opencv-python-headless>=4.8,<6"

# Install AI dependencies (disabled)
# keep in sync with the "ai" extra in gramps-web-api pyproject.toml
# RUN pip install --no-cache-dir 'pydantic-ai-slim[openai,anthropic,google,mistral,groq,bedrock]>=1.101.0,<2.0.0'

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

# copy package source from builder and install
COPY --from=builder /app/gramps-web-api/dist/gramps_webapi-${GRAMPS_WEB_API_VERSION}-py3-none-any.whl /tmp/pkg/
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "armv7l" ]; then \
        pip install \
            --no-cache-dir /tmp/pkg/gramps_webapi-${GRAMPS_WEB_API_VERSION}-py3-none-any.whl; \
    else \
        pip install \
            --no-cache-dir \
            --extra-index-url https://www.piwheels.org/simple \
            /tmp/pkg/gramps_webapi-${GRAMPS_WEB_API_VERSION}-py3-none-any.whl; \
    fi \
    && rm -rf /tmp/pkg

# download and cache YFull tree for yclade
RUN python3 -c "import yclade; yclade.tree.download_yfull_tree()"

# copy alembic archive from builder
COPY --from=builder /app/alembic.tar.gz /alembic/
COPY alembic.ini /alembic/
RUN tar -xzf /alembic/alembic.tar.gz -C /alembic

# copy frontend build, from ghcr.io/gramps-project/grampsjs:v24.12.1
# ARG GRAMPS_FRONTEND_VERSION=v24.12.1
COPY --from=ghcr.io/gramps-project/grampsjs:26.11.0 /usr/share/nginx/html /static
# COPY --from=frontend /app/gramps-web/build /static

EXPOSE 5000

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
# exec: gunicorn receives SIGTERM
# --preload loads the app once before forking the workers, so they share its memory
CMD exec gunicorn -w ${GUNICORN_NUM_WORKERS:-8} \
    -b 0.0.0.0:5000 \
    gramps_webapi.wsgi:app \
    --timeout ${GUNICORN_TIMEOUT:-120} \
    --limit-request-line 8190 \
    --preload
