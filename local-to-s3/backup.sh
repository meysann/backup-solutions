#!/bin/bash

# ===================================================================================
# Professional Automated Backup Script v3.3
#
# Author: Meysam (with assistance from Gemini)
#
# Description:
# This script creates a compressed archive of a specified directory, displays
# a real-time progress bar, logs all operations, and provides rich, colored
# visual feedback. It is designed to be robust, flexible, and professional.
#
# Features:
#   - Real-time progress bar during archiving (requires 'pv').
#   - Command-line arguments for source and destination.
#   - Detailed logging to a file.
#   - Dependency checking for required tools.
#   - Professional, colored output.
#   - Robust error handling using 'pipefail'.
# ===================================================================================

# --- Configuration & Defaults ---
# These can be overridden by command-line arguments.
DEFAULT_SOURCE_DIR="/path/to/your/important-data"
DEFAULT_BACKUP_DIR="/path/to/your/backups"

# --- Colors & Formatting ---
setup_colors() {
  GREEN='\033[0;32m'
  RED='\033[0;31m'
  BLUE='\033[0;34m'
  YELLOW='\033[1;33m'
  CYAN='\033[0;36m'
  BOLD='\033[1m'
  NC='\033[0m' # No Color
}

# --- Logging ---
# Logs messages to both the console and a log file.
log_message() {
  # This function requires LOG_FILE to be set.
  local level="$1"
  local message="$2"
  local color="$3"
  local timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")

  # Log to file (without colors)
  echo "${timestamp} [${level}] - ${message}" >> "${LOG_FILE}"

  # Log to console (with colors)
  echo -e "${color}${timestamp} [${level}] - ${message}${NC}"
}

# --- Helper Functions ---
print_separator() {
  printf "${BLUE}======================================================================${NC}\n"
}

usage() {
  echo -e "${BOLD}Usage:${NC} $0 -s <SOURCE_DIR> -b <BACKUP_DIR>"
  echo "  -s: The source directory to back up."
  echo "  -b: The directory to store backups in."
  echo "  -h: Display this help message"
  exit 1
}

check_dependencies() {
  log_message "INFO" "Checking for required tools..." "${CYAN}"
  local missing_deps=0
  for cmd in tar pv gzip; do
    if ! command -v "$cmd" &> /dev/null; then
      log_message "ERROR" "Required command '${cmd}' is not installed. Please install it to continue." "${RED}"
      missing_deps=1
    fi
  done
  if [ $missing_deps -eq 1 ]; then
    exit 1
  fi
}

cleanup() {
  if [ -f "$1" ]; then
    rm "$1"
    log_message "WARN" "Cleaned up incomplete backup file: $1" "${YELLOW}"
  fi
}

# --- Main Script Logic ---
main() {
  # Enable pipefail for robust error checking in pipelines.
  set -o pipefail

  setup_colors
  SOURCE_DIR="${DEFAULT_SOURCE_DIR}"
  BACKUP_DIR="${DEFAULT_BACKUP_DIR}"

  # Parse command-line arguments
  while getopts "s:b:h" opt; do
    case ${opt} in
      s) SOURCE_DIR="${OPTARG}" ;;
      b) BACKUP_DIR="${OPTARG}" ;;
      h) usage ;;
      *) usage ;;
    esac
  done

  # **FIXED**: Define LOG_FILE *after* parsing arguments.
  LOG_FILE="${BACKUP_DIR}/backup.log"

  # Ensure backup and log directory exists
  mkdir -p "${BACKUP_DIR}"

  print_separator
  log_message "INFO" "Starting Professional Backup Script" "${YELLOW}"
  print_separator

  check_dependencies

  log_message "INFO" "Source Directory: ${SOURCE_DIR}" "${NC}"
  log_message "INFO" "Backup Location:  ${BACKUP_DIR}" "${NC}"

  # Check if the source directory exists
  if [ ! -d "$SOURCE_DIR" ]; then
    log_message "ERROR" "Source directory '${SOURCE_DIR}' does not exist." "${RED}"
    print_separator
    exit 1
  fi

  # Create filename and destination path
  TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
  BACKUP_FILENAME="backup-${TIMESTAMP}.tar.gz"
  DESTINATION_FILE="${BACKUP_DIR}/${BACKUP_FILENAME}"

  log_message "INFO" "Backup Filename:  ${BACKUP_FILENAME}" "${NC}"
  echo ""

  # --- The Backup Process with Progress Bar ---
  # Trap CTRL+C to run cleanup function on interrupt
  trap 'cleanup "${DESTINATION_FILE}"; exit 1' INT TERM

  log_message "INFO" "Archiving files... (Press CTRL+C to cancel)" "${CYAN}"

  # Get total size for the progress bar
  TOTAL_SIZE=$(du -sb "${SOURCE_DIR}" | awk '{print $1}')

  # The core command:
  tar -cf - -C "${SOURCE_DIR}" . | pv -s "${TOTAL_SIZE}" | gzip > "${DESTINATION_FILE}"
  PIPELINE_EXIT_CODE=$? # Capture the exit code of the entire pipeline

  # Check the single exit code from the pipefail-enabled pipeline.
  if [ ${PIPELINE_EXIT_CODE} -eq 0 ]; then
    echo ""
    log_message "SUCCESS" "Backup completed successfully!" "${GREEN}"
    log_message "INFO" "File saved to: ${DESTINATION_FILE}" "${GREEN}"
  else
    echo ""
    log_message "ERROR" "Backup failed! An error occurred during the process." "${RED}"
    cleanup "${DESTINATION_FILE}" # Remove the partial backup file
    print_separator
    exit 1
  fi

  # Untrap the signal
  trap - INT TERM

  print_separator
}

# Run the main function
main "$@"

