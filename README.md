# Gramps-web image

This image is contained: fix, update build.

My modifications:
- disable pytorch
- /app contains only user content
- patch media_importer.py to support media import from zip files with non-ASCII filenames
- patch pyproject.toml to fix PyGObject version constraint (`<=3.50.0` → `<3.50.0`), since PyGObject 3.50 requires `girepository-2.0` unavailable on Debian Bookworm

image: shizacat/gramps-web:<version>
