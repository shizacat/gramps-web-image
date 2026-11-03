# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Keep a Changelog](https://keepachangelog.com/en/0.3.0/).

## [Unreleased]

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
