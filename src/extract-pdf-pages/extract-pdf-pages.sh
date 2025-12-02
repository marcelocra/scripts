#!/usr/bin/env bash
# Recursively extract text from PDF files using Poppler's pdftotext.
# Preserves directory structure under output directory.
# Usage:
#   ./extract-pdf-text.sh <input_dir> [output_dir] [--layout] [--raw] [--jobs N]
# Notes:
#   --layout  : Preserve original physical layout (columns retained)
#   --raw     : Raw order (stream order); mutually exclusive with --layout
#   --jobs N  : Parallel extraction (default 4)
# If neither --layout nor --raw is given, default pdftotext mode (reflowed) is used.
set -euo pipefail

# Early check for pdftotext presence; show explicit install commands immediately if missing.
if ! command -v pdftotext >/dev/null 2>&1; then
  echo "pdftotext not found. Install with one of:" >&2
  echo "  Debian/Ubuntu: sudo apt-get update && sudo apt-get install -y poppler-utils" >&2
  echo "  Fedora:        sudo dnf install -y poppler-utils" >&2
  echo "  Arch Linux:    sudo pacman -S poppler" >&2
  echo "  macOS (brew):  brew install poppler" >&2
  echo "After installing rerun this script." >&2
  exit 1
fi

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <input_dir> [output_dir] [--layout] [--raw] [--jobs N]" >&2
  exit 1
fi

INPUT_DIR="$1"
shift || true
OUTPUT_DIR="$INPUT_DIR/text-output"
LAYOUT_FLAG=""
JOBS=4

# Parse remaining args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --layout)
      LAYOUT_FLAG="-layout"
      ;;
    --raw)
      LAYOUT_FLAG="-raw"
      ;;
    --jobs)
      shift
      JOBS="${1:-4}"
      ;;
    *)
      # First non-flag after input_dir is output_dir (if not starting with --)
      if [[ "$1" != --* && "$OUTPUT_DIR" == "$INPUT_DIR/text-output" ]]; then
        OUTPUT_DIR="$1"
      else
        echo "Unknown argument: $1" >&2
        exit 1
      fi
      ;;
  esac
  shift || true
done

if [[ ! -d "$INPUT_DIR" ]]; then
  echo "Input directory not found: $INPUT_DIR" >&2
  exit 1
fi



mkdir -p "$OUTPUT_DIR"

echo "Input : $INPUT_DIR"
echo "Output: $OUTPUT_DIR"
if [[ -n "$LAYOUT_FLAG" ]]; then
  echo "Mode  : $LAYOUT_FLAG"
else
  echo "Mode  : default (reflowed)"
fi
echo "Jobs  : $JOBS"

# Export variables for xargs parallel function
export OUTPUT_DIR LAYOUT_FLAG

# Function to process one PDF (used by bash -c via xargs)
process_pdf() {
  local pdf="$1"
  local rel
  rel="${pdf#$INPUT_DIR/}"  # strip leading path
  local out_path
  out_path="$OUTPUT_DIR/${rel%.pdf}.txt"
  local out_dir
  out_dir="$(dirname "$out_path")"
  mkdir -p "$out_dir"
  if pdftotext $LAYOUT_FLAG "$pdf" "$out_path" 2>"$out_path.log"; then
    echo "OK  $rel" >&2
    # Remove empty log on success
    [[ -s "$out_path.log" ]] || rm -f "$out_path.log"
  else
    echo "ERR $rel" >&2
  fi
}
export -f process_pdf

# Find PDFs and process in parallel
find "$INPUT_DIR" -type f -iname '*.pdf' -print0 | xargs -0 -n1 -P "$JOBS" bash -c 'process_pdf "$0"'

echo "Done."
