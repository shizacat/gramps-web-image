# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Keep a Changelog](https://keepachangelog.com/en/0.3.0/).

## [Unreleased]

## [3.25.1-1] - 2026-11-05

### Added
- `wheels` build stage (as upstream `Dockerfile.base`): PyGObject (`<3.50.0`), pycairo, PyICU are compiled there and installed into the main image as wheels.
- Packages `ca-certificates`, `gir1.2-pango-1.0`, `poppler-data`, `tesseract-ocr-osd` (as upstream).
- `ENV OMP_NUM_THREADS=1` (limit OpenMP and BLAS of NumPy and OpenCV, as upstream).

### Changed
- Update gramps-web-api `v3.24.0` → `v3.25.1` (see "Изменения gramps-web-api" below).
- Update frontend `grampsjs:26.10.2` → `grampsjs:26.11.0`.
- Main image: `apt-get install --no-install-recommends`, only runtime libraries (`libcairo2`, `libcairo-gobject2`, `libgirepository-1.0-1`, `libicu76`) instead of `-dev` packages.
- Pillow is no longer pinned `<12` (upstream unpinned it).
- PostgreSQL driver comes from pip (`psycopg2-binary`, gramps-web-api dependency) instead of Debian `python3-psycopg2`.
- gunicorn is started with `exec` (receives SIGTERM) and `--preload` (workers share the app memory).
- Rewrite patch `gramps_web_api_0002_pygobject_version.patch` for the new `pyproject.toml`.
- Commented AI dependencies updated to upstream `pydantic-ai-slim[...]`.

### Removed
- `flock` around the user DB migration: upstream serializes migrations itself (#1139).
- Packages `appstream`, `pkg-config`, `python3-pip`, `libcairo2-dev`, `libgirepository1.0-dev`, `libicu-dev`, `libpq-dev`, `python3-psycopg2`, `libgl1-mesa-dev`, `libgtk2.0-dev`, `libopenblas-dev`.
- Commented PyTorch and sentence-transformers steps (removed upstream together with semantic search).

### Изменения gramps-web-api (v3.24.0 → v3.25.1)
- Миграции БД пользователей: 17 → 18 (refresh-токены отзываются при смене пароля или отключении пользователя, #1129). Миграции теперь выполняются в одной транзакции под блокировкой — web и celery не мигрируют одновременно (#1139). Перед обновлением нужен бэкап `/app/users`.
- Поиск: `sifts` заменён собственным поисковым индексом (SQLite FTS5 / PostgreSQL), исправлены утечки приватных имён через семьи и события (#1089). Старые таблицы удаляются, индекс строится заново в фоне, если настроена очередь задач (celery); иначе — вручную.
- Семантический поиск удалён (#1088), `VECTOR_EMBEDDING_MODEL` игнорируется.
- Приватность: private proxy заменён на `RestrictedDb` (#1107), приватные записи не влияют на оценку «вероятно жив» (#1101), 404 вместо 500 для приватных медиа и людей без ViewPrivate (#1122, #1084).
- Безопасность: Authlib ≥ 1.9.0 из-за CVE-2026-96760 (#1140), нельзя изменить пользователя с более высокой ролью (#1132), регистрация и пароли отклоняются при отключённой локальной аутентификации (#1103).
- Миниатюры: TIFF с XMP-метаданными не в bytes (#1114).
- Производительность: сортировка и пагинация списков в SQL (#1110), индекс в таблице изменений undo (#1093), `--preload` для gunicorn (#1126).
- Импорт: понятная причина ошибки импорта, надёжное определение GEDCOM 7 (#1120).
- Удаление объектов по handle в фоне (#1131), прогресс задач хранится в result backend, а не в БД пользователей (#1118).
- Pillow без верхнего ограничения версии, `psycopg2-binary` — прямая зависимость.

## [3.24.0-1] - 2026-11-03

### Added
- Fonts `fonts-dejavu-core`, `fonts-noto-core` for non-Latin scripts in PDF reports (`fonts-noto-cjk` is skipped).

### Changed
- Update gramps-web-api `v3.21.0` → `v3.24.0` (see "Изменения gramps-web-api" below).
- Update frontend `grampsjs:26.8.1` → `grampsjs:26.10.2`.
- Rewrite patch `gramps_web_api_0001_media_import.patch` for the new `media_importer.py` (3 `zipfile.ZipFile` calls).
- OpenCV `opencv-contrib-python-headless<5` → `opencv-python-headless>=4.8,<6` (as the upstream "face" extra).

### Fixed
- User DB migration is run under `flock /app/users/.migrate.lock`: containers sharing `/app/users` (web and celery) no longer migrate concurrently (`table task_tree already exists`).

### Изменения gramps-web-api (v3.21.0 → v3.24.0)
- Миграции БД пользователей: 13 → 17 (снято ограничение уникальности email #961, sync-токены на устройство #1033, push-подписки #1001, учёт задач, меняющих дерево, #1049). Перед обновлением нужен бэкап `/app/users`.
- Миниатюры: исправлены миниатюры для изображений в оттенках серого (#994), сохраняется форма страницы PDF (#1057).
- Карта: новый эндпоинт `/places/coordinates/` (#1016), поддержка MIME-типов файлов карт (#1052).
- Приватность: приватные объекты больше не попадают в публичный поисковый индекс (#1035), приватные ссылки и фамилии скрыты от пользователей без ViewPrivate (#1079), исправлено двойное применение private proxy (#986). Рекомендуется переиндексация поиска.
- Бэкапы: хранимые бэкапы дерева и восстановление из них (#1065), экспорт из согласованного снимка (#1061), экспортёр GEDCOM 7 (#1034).
- OIDC: PKCE (#1028), привязка и отвязка OIDC-аккаунтов к текущему пользователю (#1051, #1053), исправлена ошибка 500 для отключённых аккаунтов (#998).
- Фильтры: правило GOQL (`MatchesQuery`), параметр `oql` удалён (#1013).
- Данные: отмена удаления без force (#1006), неизвестные ключи при валидации отклоняются (#1004) и удаляются при check & repair (#1060), пустые ссылки на объекты исправляются (#952).
- Производительность: быстрее пагинация (#985) и полная переиндексация (#958), большие медиа-архивы отдаются без буферизации (#1059), обновление индекса не блокирует транзакции (#990).
- Безопасность: локальные медиа не пишутся за пределы базовой папки (#960), обрезанные загрузки отклоняются (#989), нельзя понизить последнего владельца дерева (#973).
- Устарело: семантический поиск (#1074), отдельный (не shared) PostgreSQL (#981), настройки, хранимые в БД (#1050).
- Язык сервера всегда английский (#1042), удалена поддержка Python 3.10 (#1067).

## [3.21.0-1] - 2026-11-03

### Changed
- Update gramps-web-api `v3.12.2` → `v3.21.0` (see "Изменения gramps-web-api" below).
- Update frontend `grampsjs:26.4.3` → `grampsjs:26.8.1`.

### Изменения gramps-web-api (v3.12.2 → v3.21.0)
- Миграции БД пользователей: 9 → 13 (фоновые задачи в БД #827, настройки отдельно для каждого дерева #833, постоянные токены доступа #790). Применяются автоматически при старте, откат на старый образ невозможен — нужен бэкап `/app/users`.
- Резервное копирование: восстановление из бэкапа (#899), пробный запуск импорта (#902).
- Объединение объектов (#867), удаление по handle (#874), вложенные и кросс-доменные фильтры (#828, #852), быстрые POST-эндпоинты `.../query/` (#913).
- Лента годовщин в формате ICS (#792).
- Миниатюры: ограничение размера и эффективнее для PDF (#841), настраиваемый `MAX_THUMBNAIL_FILE_BYTES` (#861), исправлена ориентация EXIF при обрезке (#850), обработка отсутствующих файлов (#887).
- Карта: медиа-объекты как источник тайлов (#879), ограничение зума оверлеев (#898), кеш-заголовки для тайлов (#903).
- OIDC: обмен кодом (#928), роли из ID-токена для Microsoft Entra (#894).
- Исправления данных: пересчёт sortval у дат при записи (#870), пересборка пользовательских типов при проверке БД (#890), корректное удаление персоны по умолчанию (#845).
- Логи в формате JSON (#878, #919), опциональный Sentry (#922, в образ не включён).
- Тяжёлые опциональные зависимости импортируются лениво (#920).

## [3.12.2-3] - 2026-11-03

### Fixed
- Media thumbnails failed with `KeyError: 'AVIF'`: install Pillow from PyPI (with AVIF support) instead of Debian `python3-pil`.

## [3.12.2-2] - 2026-11-03

### Fixed
- Install OpenCV (`opencv-contrib-python-headless<5`), it was missing ("OpenCV is not installed").

## [3.12.2-1] - 2026-11-03

### Added
- Download and cache YFull tree for yclade at build time.
- `docs/01.migration.md` with upgrade analysis.

### Changed
- Update gramps-web-api `v3.7.1.1` → `v3.12.2` (see "Изменения gramps-web-api" below).
- Update frontend `grampsjs:26.2.0` → `grampsjs:26.4.3`.
- Switch base image Debian Bookworm → Debian Trixie (builder: `python:3.13-slim-trixie`).
- Install Python packages into venv `/venv` (`--system-site-packages`) instead of system pip with `--break-system-packages`.
- NumPy from Debian (`python3-numpy`) instead of pip `numpy<2` (no wheels for Python 3.13).

### Removed
- Unused `cmake`, `libatlas-base-dev`, duplicate `localedef`, `OMP_NUM_THREADS`, `PYTHONPATH`.

### Изменения gramps-web-api (v3.7.1.1 → v3.12.2)
- Миниатюры генерируются в формате AVIF (#800), у эндпоинтов миниатюр появился необязательный параметр checksum (#801).
- Добавлен пол «другой» (#795).
- Безопасность: пользовательские фильтры требуют прав (#513), пустой пароль запрещён (#784), импорт медиа не может писать за пределы временной папки, прокси приватных данных очищает объекты (#804).
- Исправления данных: локализованные названия типов больше не портят типы событий (#770), ссылки на рождение и смерть обновляются после смены типа события (#797).
- Исправлена регрессия входа через OIDC (#799).
- Производительность: кеширование метаданных БД (#809, #811), меньше чтения с диска при загрузке БД (#810), ускорено «удалить всё» (#825).
- Новая опция конфигурации `PILLOW_MAX_IMAGE_PIXELS` (#774).
- Можно редактировать данные исследователя (#788) и переименовать базу в режиме одного дерева (#789).
- Места: родительские места можно не включать в профиль (#802), ссылки на место добавлены в расширенные атрибуты (#806).
- История отмены: почищена миграция базы истории отмены (#816), исправлен пробный запуск (#826).
