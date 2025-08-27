# Backup Solution: Local Filesystem

This script creates a compressed `.tar.gz` archive of a specified local directory. It features a real-time progress bar, detailed logging, and robust error handling.

## Prerequisites

Before running this script, you must have `pv` installed:
- *On Debian/Ubuntu:* `sudo apt install pv`
- *On RHEL/CentOS:* `sudo yum install pv`

## Usage

Run the script with the `-s` (source) and `-b` (backup) flags:
```bash
./backup.sh -s /path/to/your/data -b /path/to/your/backups
