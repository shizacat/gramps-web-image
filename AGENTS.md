# AGENTS.md

Собственный Docker-образ [Gramps Web](https://github.com/gramps-project/gramps-web-api): API собирается из исходников с патчами, фронтенд копируется из `ghcr.io/gramps-project/grampsjs`.

## Структура

- `Dockerfile` — builder (checkout тега gramps-web-api, патчи, wheel, архив `alembic_users`) + основной образ на `debian:trixie`.
- `docker-entrypoint.sh` — создание каталогов в `/app`, секретный ключ, миграции БД пользователей (под `flock`).
- `patches/` — патчи к gramps-web-api, накладываются `patch -p1` в builder.
- `alembic.ini` — свой конфиг alembic (из upstream берётся только `alembic_users`).
- `README.md`, `CHANGELOG.md`, `docs/01.migration.md` — документация.
- `tmp/` — временные клоны upstream (`tmp/gwa` — gramps-web-api, `tmp/gw` — gramps-web), в `.gitignore`. Клонировать только сюда, не в `/tmp`.

## Окружение

- Docker локально не установлен: образ не собирать, проверять статически. В ответе явно писать, что сборка не проверялась.
- `gh` не авторизован: теги смотреть через `git ls-remote --tags` или клоны в `tmp/`, наличие тега фронтенда — через registry API ghcr.io (анонимный токен).

## Обновление версии

Обновляться пошагово, на ближайшую безопасную версию, а не сразу на последнюю. Перед шагом сравнить upstream между текущим и целевым тегом:

1. `pyproject.toml` — зависимости, `requires-python`, extras (`ai`, `face`, `sentry`).
2. `Dockerfile`, `Dockerfile.base`, `docker-entrypoint.sh` — что перенести к нам или осознанно не переносить.
3. `gramps_webapi/config.py` — новые настройки по умолчанию (пути, лимиты).
4. `alembic_users/versions` и `alembic_users/env.py` — число и суть миграций БД пользователей.
5. Патчи: `patch -p1 --dry-run` на целевом теге; при ошибке переписать патч через `git diff` на этом теге.
   Проверить не испралена ли проблема в новой версии.
6. Фронтенд: upstream собирает его поверх `gramps-webapi:latest`, поэтому брать последний тег `grampsjs`, вышедший до следующей версии API. Проверить, что тег есть в ghcr.io (теги без `v`).

В `Dockerfile` версия меняется в трёх местах: тег в builder (`v3.24.0`), версия пакета из `gramps_webapi/_version.py` в основном образе (`3.24.0`), тег `grampsjs` в `COPY --from`.

Если есть новые миграции — в ответе предупредить о бэкапе `/app/users` (отката нет).

## Соглашения в Dockerfile

- Следовать подходу upstream, отличия — только осознанные и описанные в `README.md` (My modifications).
- То, что намеренно выключено (PyTorch, AI, языки tesseract, `fonts-noto-cjk`), оставлять закомментированным с причиной.
- Комментарии в `Dockerfile` — на английском, кратко, только причина/ограничение.
- Python-пакеты — в venv `/venv` (`--system-site-packages`), без `--break-system-packages`.
- NumPy — из Debian (`python3-numpy`): wheels NumPy 2.x с PyPI требуют X86_V2 (старые CPU).
- Pillow — с PyPI (нужен AVIF для миниатюр), с ограничением версии из `pyproject.toml` upstream.
- OpenCV — как extra `face` upstream (`opencv-python-headless`).

## Документация

- `README.md`: блок «Based on» (версии API, фронтенда, Gramps, Debian) и список «My modifications» держать актуальными.
- `CHANGELOG.md`: формат [Keep a Changelog 0.3.0](https://keepachangelog.com/en/0.3.0/), версии `<версия API>-<номер сборки>` (`3.24.0-1`), разделы Added/Changed/Removed/Fixed на английском. Изменения upstream — отдельным разделом на русском «Изменения gramps-web-api (vX → vY)» с номерами PR.
- `docs/01.migration.md`: обновлять строку «Статус» после каждого шага.
