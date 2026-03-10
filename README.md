# Gramps-web image

This image is contained: fix, update build.

My modifications:
- disable pytorch
- /app contains only user content
- patch media_importer.py to support media import from zip files with non-ASCII filenames

image: shizacat/gramps-web:<version>
