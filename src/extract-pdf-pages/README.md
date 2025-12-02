# **PDF Processing Scripts - Conversation Summary**

## **Context**

User needed scripts to process \~100 PDF files for two purposes:

1. Extract first N pages (1-5) from each PDF
2. Extract full text content from text-based PDFs

**Environment:** Any. Focus on having the most useful tools necessary.

## **Deliverables Created**

### 1. extract-pdf-pages.py

**Purpose:** Extract first N pages from multiple PDFs

**Features:**

- Recursively searches nested directories (`**/*.pdf`)
- Extracts pages 1-N or pages 2-(N+1) with `--skip-first` flag
- Uses `pypdf` library (cross-platform Python)
- Auto-generates output filenames: `original_name_first_N_pages.pdf` or `original_name_pages_2_to_N.pdf`
- Progress indicators and error handling

**Installation:**

```
pip install pypdf
```

**Usage:**

```
# Extract first 3 pages from all PDFs
python scripts/extract-pdf-pages.py ./pdfs 3

# Extract pages 2-4 (skip first page)
python scripts/extract-pdf-pages.py ./pdfs 3 --skip-first

# Custom output directory
python scripts/extract-pdf-pages.py ./pdfs 5 ./output
```

**Key Implementation Details:**

- Takes arguments: `<input_dir> <num_pages> [output_dir] [--skip-first]`
- `--skip-first` flag can appear anywhere in arguments
- Handles PDFs with fewer pages than requested
- Default output: `<input_dir>/extracted/`

### 2. `scripts/extract-pdf-text.sh`

**Purpose:** Extract full text content from text-based PDFs (not scanned images)

**Features:**

- Uses Poppler's `pdftotext` (fastest, best quality for digital PDFs)
- Parallel processing (default 4 jobs, configurable via `--jobs N`)
- Three extraction modes:
  - Default: reflowed text (reading order)
  - `--layout`: preserves physical layout (columns, positioning)
  - `--raw`: stream order (as stored in PDF)
- Preserves directory structure in output
- Early dependency check with explicit install commands for Debian/Ubuntu/Fedora/Arch/macOS

**Installation:**

```sh
# Debian/Ubuntu
sudo apt-get update && sudo apt-get install -y poppler-utils

# Fedora
sudo dnf install -y poppler-utils

# Arch
sudo pacman -S poppler

# macOS
brew install poppler
```

**Usage:**

```sh
# Default reflowed mode
./scripts/extract-pdf-text.sh ./pdfs

# Preserve layout (good for columned documents)
./scripts/extract-pdf-text.sh ./pdfs --layout

# Custom output + raw mode + 8 parallel jobs
./scripts/extract-pdf-text.sh ./pdfs ./text-output --raw --jobs 8
```

**Key Implementation Details:**

- Arguments: `<input_dir> [output_dir] [--layout] [--raw] [--jobs N]`
- Default output: `<input_dir>/text-output/`
- Creates `.log` files on errors, removes empty logs on success
- Uses `find` + `xargs` for parallel processing
- Exports bash function for parallel execution

### 3. `scripts/extract-pdf-text.mjs`

**Purpose:** Node.js alternative for text extraction

**Features:**

- Uses `pdf-parse` library (pdf.js wrapper)
- Reflowed text output
- Preserves directory structure
- Clear dependency error if `pdf-parse` not installed

**Installation:**

```
pnpm add pdf-parse
```

**Usage:**

```
node scripts/extract-pdf-text.mjs ./pdfs
node scripts/extract-pdf-text.mjs ./pdfs ./custom-output
```

**Note:** TypeScript lint errors appear but script runs fine (runtime Node, no type declarations needed)

## **Tool Recommendations Given**

**For page extraction:**

- `pypdf` - chosen for simplicity, cross-platform, adequate performance

**For text extraction (priority order):**

1. `pdftotext` **(Poppler)** - fastest, best quality, native binary (chosen for bash script)
2. `PyMuPDF` **(**`fitz`**)** - if you need positional info, block coordinates, or future semantic chunking
3. `pdfminer.six` - best logical text flow for complex layouts (academic/legal docs)
4. `pdf-parse` **(Node)** - convenient if staying in JS ecosystem (chosen for mjs script)
5. `ocrmypdf` **+ Tesseract** - only if PDFs are scanned images (not applicable here)

## **Design Decisions**

- Bash script preferred over Python for text extraction (faster, native tool)
- Added Node alternative for users in JS workflow
- `--skip-first` flag added to page extractor per user request
- Recursive directory search for both scripts
- Parallel processing for text extraction (bash only)
- Early dependency checks with explicit install commands

## **Evolution During Conversation**

1. Initial request → Python page extractor created
2. Added recursive nested folder support (`*.pdf` → `**/*.pdf`)
3. Added `--skip-first` flag for page extraction
4. Discussed text extraction tools → created bash + Node scripts
5. Refined bash script with early dependency check and clearer install messages

## **Files Modified/Created**

- extract-pdf-pages.py - created, then modified twice
- scripts/extract-pdf-text.sh - created, then refined
- scripts/extract-pdf-text.mjs - created
- memos/pages/Programa para ler um conjunto de arquivos em PDF e extrair algumas paginas dele.md - updated with solution
