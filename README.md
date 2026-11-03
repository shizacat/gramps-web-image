# Gramps-web image

This image is contained: fix, update build.

Based on:
- [gramps-web-api](https://github.com/gramps-project/gramps-web-api) `v3.12.2` (Python package `gramps_webapi` 3.12.2)
- [gramps-web](https://github.com/gramps-project/gramps-web) frontend `26.4.3` (`ghcr.io/gramps-project/grampsjs:26.4.3`)
- Gramps 6.0 (`gramps60` addons), Debian Trixie

My modifications:
- disable pytorch
- OpenCV as `opencv-contrib-python-headless<5` instead of `opencv-contrib-python`
- disable ai option for gramps-web-api (no sentence-transformers and model)
- /app contains only user content
- frontend is bundled into the image (`/static`)
- tesseract only with `eng` and `rus` languages
- patch media_importer.py to support media import from zip files with non-ASCII filenames
- patch pyproject.toml to fix PyGObject version constraint (`<=3.50.0` → `<3.50.0`), so it builds against `libgirepository1.0-dev` (PyGObject 3.50 requires `girepository-2.0`)
- NumPy from Debian (`python3-numpy`) to avoid X86_V2 baseline requirement of PyPI wheels on older CPUs

image: shizacat/gramps-web:<version>
