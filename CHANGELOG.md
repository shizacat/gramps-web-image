# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Keep a Changelog](https://keepachangelog.com/en/0.3.0/).

## [Unreleased]

## [3.12.2-1] - 2026-11-03
### Added
- Download and cache YFull tree for yclade at build time.
- `docs/01.migration.md` with upgrade analysis.

### Changed
- Update gramps-web-api `v3.7.1.1` → `v3.12.2`.
- Update frontend `grampsjs:26.2.0` → `grampsjs:26.4.3`.
- Switch base image Debian Bookworm → Debian Trixie (builder: `python:3.13-slim-trixie`).
- Install Python packages into venv `/venv` (`--system-site-packages`) instead of system pip with `--break-system-packages`.
- NumPy from Debian (`python3-numpy`) instead of pip `numpy<2` (no wheels for Python 3.13).

### Removed
- Unused `cmake`, `libatlas-base-dev`, duplicate `localedef`, `OMP_NUM_THREADS`, `PYTHONPATH`.
