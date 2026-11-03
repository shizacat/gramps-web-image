# Gramps-web image

This image is contained: fix, update build.

Based on:
- [gramps-web-api](https://github.com/gramps-project/gramps-web-api) `v3.7.1.1` (Python package `gramps_webapi` 3.7.1)
- [gramps-web](https://github.com/gramps-project/gramps-web) frontend `26.2.0` (`ghcr.io/gramps-project/grampsjs:26.2.0`)
- Gramps 6.0 (`gramps60` addons), Debian Bookworm

My modifications:
- disable pytorch
- /app contains only user content
- patch media_importer.py to support media import from zip files with non-ASCII filenames
- patch pyproject.toml to fix PyGObject version constraint (`<=3.50.0` → `<3.50.0`), since PyGObject 3.50 requires `girepository-2.0` unavailable on Debian Bookworm
- pin NumPy < 2.0 to avoid X86_V2 baseline requirement on older CPUs
- Disable ai option for gramps-web-api

image: shizacat/gramps-web:<version>
