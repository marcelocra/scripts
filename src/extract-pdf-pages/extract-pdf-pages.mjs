#!/usr/bin/env node
// Recursively extract text from PDFs using pdf-parse (pdf.js under the hood).
// Usage:
//   node scripts/extract-pdf-text.mjs <input_dir> [output_dir]
// Install dependency first:
//   pnpm add pdf-parse
// Falls back with a clear error if pdf-parse is missing.

import { promises as fs } from "fs";
import path from "path";
import process from "process";

let pdfParse;
try {
  ({ default: pdfParse } = await import("pdf-parse"));
} catch (e) {
  console.error("Dependency pdf-parse not installed. Run: pnpm add pdf-parse");
  process.exit(1);
}

if (process.argv.length < 3) {
  console.error(
    "Usage: node scripts/extract-pdf-text.mjs <input_dir> [output_dir]"
  );
  process.exit(1);
}

const inputDir = path.resolve(process.argv[2]);
const outputDir = path.resolve(
  process.argv[3] || path.join(inputDir, "text-output-node")
);

async function listPdfFiles(dir) {
  const entries = await fs.readdir(dir, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...(await listPdfFiles(fullPath)));
    } else if (entry.isFile() && entry.name.toLowerCase().endsWith(".pdf")) {
      files.push(fullPath);
    }
  }
  return files;
}

async function extractPdf(pdfPath) {
  const data = await fs.readFile(pdfPath);
  const result = await pdfParse(data); // result.text
  return result.text; // Plain reflowed text
}

async function main() {
  try {
    await fs.mkdir(outputDir, { recursive: true });
    const pdfs = await listPdfFiles(inputDir);
    if (!pdfs.length) {
      console.log("No PDF files found.");
      return;
    }
    console.log(`Found ${pdfs.length} PDF files`);
    for (const pdf of pdfs) {
      const rel = path.relative(inputDir, pdf);
      const outPath = path.join(outputDir, rel.replace(/\.pdf$/i, ".txt"));
      await fs.mkdir(path.dirname(outPath), { recursive: true });
      try {
        const text = await extractPdf(pdf);
        await fs.writeFile(outPath, text, "utf8");
        console.log(`OK  ${rel}`);
      } catch (e) {
        console.error(`ERR ${rel}: ${e.message}`);
      }
    }
    console.log("Done.");
  } catch (e) {
    console.error("Fatal:", e);
    process.exit(1);
  }
}

main();
