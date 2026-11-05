# Gramps-web image

This image is contained: fix, update build.

Based on:
- [gramps-web-api](https://github.com/gramps-project/gramps-web-api) `v3.25.1` (Python package `gramps_webapi` 3.25.1)
- [gramps-web](https://github.com/gramps-project/gramps-web) frontend `26.11.0` (`ghcr.io/gramps-project/grampsjs:26.11.0`)
- Gramps 6.0 (`gramps60` addons), Debian Trixie
- Image structure follows upstream `Dockerfile.base` (wheels stage for PyGObject/pycairo/PyICU, no compiler in the main image)

My modifications:
- disable ai option for gramps-web-api (no `pydantic-ai-slim`)
- gramps-web-api is built from sources with patches (separate builder stage)
- /app contains only user content
- frontend is bundled into the image (`/static`)
- tesseract only with `eng` and `rus` languages
- no `fonts-noto-cjk` (Chinese/Japanese/Korean fonts for reports)
- patch media_importer.py to support media import from zip files with non-ASCII filenames
- patch pyproject.toml to fix PyGObject version constraint (`<=3.50.0` → `<3.50.0`), so it builds against `libgirepository1.0-dev` (PyGObject 3.50 requires `girepository-2.0`); the wheels stage uses the same constraint
- NumPy from Debian (`python3-numpy`) to avoid X86_V2 baseline requirement of PyPI wheels on older CPUs

image: shizacat/gramps-web:<version>
