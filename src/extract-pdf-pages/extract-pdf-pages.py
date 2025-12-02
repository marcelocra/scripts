#!/usr/bin/env python3
"""
Extract the first N pages from multiple PDF files.

Usage:
    python extract-pdf-pages.py <input_directory> <num_pages> [output_directory] [--skip-first]

Example:
    python extract-pdf-pages.py ./pdfs 3
    python extract-pdf-pages.py ./pdfs 5 ./extracted
    python extract-pdf-pages.py ./pdfs 4 ./extracted --skip-first
"""

import sys
from pathlib import Path

try:
    from pypdf import PdfReader, PdfWriter
except ImportError:
    print("Error: pypdf not installed. Install with: pip install pypdf")
    sys.exit(1)


def extract_first_n_pages(input_path, output_path, num_pages, skip_first=False):
    """Extract the first N pages from a PDF file."""
    try:
        reader = PdfReader(input_path)
        writer = PdfWriter()

        # Calculate start page and pages to extract
        start_page = 1 if skip_first else 0
        end_page = start_page + num_pages
        pages_to_extract = min(end_page, len(reader.pages))

        for page_num in range(start_page, pages_to_extract):
            writer.add_page(reader.pages[page_num])

        with open(output_path, "wb") as output_file:
            writer.write(output_file)

        return True, pages_to_extract
    except Exception as e:
        return False, str(e)


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)

    # Parse arguments
    skip_first = "--skip-first" in sys.argv
    args = [arg for arg in sys.argv[1:] if arg != "--skip-first"]

    input_dir = Path(args[0])
    num_pages = int(args[1])
    output_dir = Path(args[2]) if len(args) > 2 else input_dir / "extracted"

    if not input_dir.exists():
        print(f"Error: Input directory '{input_dir}' does not exist")
        sys.exit(1)

    if not 1 <= num_pages <= 5:
        print("Warning: num_pages should be between 1 and 5")

    # Create output directory if it doesn't exist
    output_dir.mkdir(parents=True, exist_ok=True)

    # Find all PDF files recursively in nested folders
    pdf_files = list(input_dir.glob("**/*.pdf"))

    if not pdf_files:
        print(f"No PDF files found in '{input_dir}'")
        sys.exit(0)

    print(f"Found {len(pdf_files)} PDF files")
    if skip_first:
        print(f"Extracting pages 2-{num_pages + 1} from each (skipping first page)...")
    else:
        print(f"Extracting first {num_pages} pages from each...")
    print(f"Output directory: {output_dir}\n")

    success_count = 0
    error_count = 0

    for pdf_path in pdf_files:
        if skip_first:
            output_filename = f"{pdf_path.stem}_pages_2_to_{num_pages + 1}.pdf"
        else:
            output_filename = f"{pdf_path.stem}_first_{num_pages}_pages.pdf"
        output_path = output_dir / output_filename

        success, result = extract_first_n_pages(
            pdf_path, output_path, num_pages, skip_first
        )

        if success:
            print(f"✓ {pdf_path.name} -> {output_filename} ({result} pages)")
            success_count += 1
        else:
            print(f"✗ {pdf_path.name} - Error: {result}")
            error_count += 1

    print(f"\nComplete: {success_count} successful, {error_count} errors")


if __name__ == "__main__":
    main()
