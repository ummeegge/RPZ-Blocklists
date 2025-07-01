# Changelog

All notable changes to this project will be documented in this file.

---

## [0.4.3] - 2025-07-01
### Added

- Defined @INPUT_FORMATS array to centralize supported input formats (Hosts, Adblock Plus, Plain Domain, CSV/Tab-separated, URL) for easier extension
- Added open_file function to centralize file operations and automatically create directories
- Added initialize_list_stats and initialize_hash_entry functions to streamline initialization of %list_stats and %hashes
- Added format_relative_time function to unify time formatting for SOURCES.md
- Introduced constants (HASH_FILE, SOURCES_MD, STATUS_UPDATED, STATUS_NO_UPDATES, STATUS_NOT_REACHABLE, STATUS_OUTDATED, MAX_FAILED_ATTEMPTS, REPO_URL_BASE) for improved maintainability

### Changed

- Refactored convert_blocklist_to_rpz to use @INPUT_FORMATS for domain parsing, improving extensibility and debugging with original line logging
- Updated status report generation to use constants for status values and initialize %status_counts explicitly
- Improved handle_failed_attempt to use new initialization functions and constants
- Combined license cleaning regex in SOURCES.md generation for efficiency
- Updated documentation to reference @INPUT_FORMATS for supported input formats
- Incremented version to 0.4.3

### Fixed

- Fixed Use of uninitialized value warning in status summary by initializing %status_counts with all possible status values using constants
- Fix domain extraction: use correct regex group for domain, not match position

### Removed

- Removed redundant code for input format parsing in convert_blocklist_to_rpz.
- Removed duplicate time formatting logic in SOURCES.md generation, replaced by format_relative_time.

---

## [0.4.2] – 2025-06-30

### Added
- docs: overhaul README.md with new structure and extended documentation
- Added clear project overview and feature list
- Listed all supported input formats for blocklist conversion
- Documented SOURCES.md columns and status definitions
- Included usage instructions, integration tips, and repo structure
- Improved guidance for contributors and clarified licensing

### Changed
- Update SOURCES.md generation: remove redundant license, use short license names, replace File Path with Source URL, use relative time for Last Updated
- Enhanced blocklist2rpz-multi.pl:
- Improved stability for processing 53 sources
- Added handling for empty lines in urllist.txt
- Updated source-hashes.csv with new hashes and domain counts
- Added overwriting of existing RPZ files when content changes are detected (e.g., for renamed or updated sources)
- Updated `SOURCES.md` generation to show "Last Updated" only for actual content updates, with a new "Last Checked" column for the last check time
- Added `last_updated` field in source-hashes.csv to track actual content changes (based on hash/ETag diff)
- Use `last_updated` for SOURCES.md Last Updated column for accurate change tracking
- Improved time parsing for SOURCES.md generation
- Consistent handling of outdated sources with "30+ Days" display
- Fixed duplicate validation entries in validation.txt
- Standardized last_updated to ISO format in source-hashes.csv
- Added Outdated status to status.txt summary
- Enhanced debug logging for update/skip reasons

---

## [0.4.1] – 2025-06-29

### Added
- Cleanup logic in `blocklist2rpz` for removed addresses
- Fixed duplicate `No`/`Updates` lines in `status.txt` Status Summary.
- Added separator lines to Status Summary for better readability.
- Enhanced ETag/Hash change detection and SOURCES.md generation.

### Changed
- Remove Mandiant URL since it is too old
- Update Frogeye license
- Updated Bitbucket URL

---

## [0.4.0] – 2025-06-28

### Added
- Dynamic file size units (B, KB, MB, GB) in `SOURCES.md`
- More space for the "Size" entry in `SOURCES.md`
- Epic ASCII banner in README

### Changed
- Removed `-KB` from the `source-hashes.csv` header, updated `SOURCES.md` accordingly
- Improved Status Summary output: added separator lines and explicit initialization
- Updated documentation to version 1.4 (future updates will be tracked in the Changelog instead of script comments)

---

## [0.3.3] – 2025-06-27

### Changed
- Updated RPZ blocklists and source hashes
- Updated Frogeye source

### Removed
- Removed Hagezi phishing list as it is no longer reachable
- Removed Mandiant URL

---

## [0.3.2] – 2025-06-27

### Fixed
- Fixed cache path in workflow
- Fixed YAML syntax in `update-rpz.yml` by adding missing `path:` key
- Cosmetic improvements

### Changed
- Updated README with new features and structure

---

## [0.3.1] – 2025-06-27

### Fixed
- Fixed wide character error when writing RPZ files by using `:raw` and explicit encoding
- Fixed syntax error by removing duplicate if block and standardizing indentation

---

## [0.3.0] – 2025-06-27

### Added
- ETag/Hash change detection for blocklists in `blocklist2rpz-multi.pl`
- Hash-checking feature in `blocklist2rpz-multi.pl`
- Improved generation of `SOURCES.md`, enhanced SOURCES.md with persistent stats
- Fixed duplicate file creation
---

## [0.2.2] – 2025-06-27

### Added
- Explicit `git add` commands in workflow for `SOURCES.md`
- Set timeout for `update-rpz.yml` to 45 minutes

---

## [0.2.1] – 2025-06-27

### Fixed
- Minor bugfixes and workflow tweaks

---

## [0.2.0] – 2025-06-27

### Added
- Introduce `Changelog.md` version with basic functionality from version 1.2

