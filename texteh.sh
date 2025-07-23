#!/bin/bash

# textEh - A tool to export your git repository's codebase into text dumps.
# Useful for creating readable, compressed, or chunked versions of your code for analysis, backups, or sharing.
# Copyright (C) 2025 [Your Name Here]
# Version: v0.1.0
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# See the LICENSE file for details.

VERSION="v0.1.0"

set -e  # Exit on errors

# Check if we're in a git repository (required to respect .gitignore)
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: textEh must be run inside a git repository to respect .gitignore."
  exit 1
fi

echo "Running textEh version $VERSION"

# Get the project root and current run directory
PROJECT_ROOT=$(git rev-parse --show-toplevel)
RUN_DIR=$(pwd)

# Change to project root for consistent paths
cd "$PROJECT_ROOT"

# Create output directory if it doesn't exist
mkdir -p texteh

# Backup existing files in texteh (overwrite old backups, keep only one)
if [ -f texteh/texteh_full_dump.txt ]; then
  mv -f texteh/texteh_full_dump.txt texteh/texteh_full_dump.txt.bak
fi

if [ -f texteh/texteh_compressed_dump.txt ]; then
  mv -f texteh/texteh_compressed_dump.txt texteh/texteh_compressed_dump.txt.bak
fi

if [ -f texteh/texteh_chunk_toc.md ]; then
  mv -f texteh/texteh_chunk_toc.md texteh/texteh_chunk_toc.md.bak
fi

# Get file list BEFORE creating output files to avoid self-inclusion
# Since we're in root, paths are relative to root
mapfile -d '' files < <(git ls-files -c -o --exclude-standard -z)

# Create/empty the file
DUMP_FILE="texteh/texteh_full_dump.txt"
truncate -s 0 "$DUMP_FILE"

# Array to store file info for later chunking
declare -a file_list=()
declare -a file_starts=()
declare -a file_ends=()

cum_size=0

# Loop over files to build full dump and compute positions
for file in "${files[@]}"; do
  if [[ -z "$file" ]]; then continue; fi  # Skip empty entries
  if [[ "$file" =~ ^texteh/ ]]; then continue; fi  # Skip anything in texteh
  if [[ "$file" =~ ^texteh_(full|compressed)_dump\.txt(\.bak)?$ ]]; then continue; fi  # Skip dump files and backups (in case)
  if [[ "$file" =~ \.md$ ]]; then continue; fi  # Skip .md files
  if [ -f "$file" ]; then  # Only process if file exists
    {
      echo "=== $file ==="
      cat "$file"
      echo -e "\n---\n"  # Separator for readability
    } >> texteh/texteh_full_dump.txt

    # Compute compressed contribution
    contrib=$( { echo "=== $file ==="; cat "$file"; echo -e "\n---\n"; } | tr -d ' \t\n\r' | wc -c )
    start=$cum_size
    cum_size=$((cum_size + contrib))
    end=$cum_size

    file_list+=("$file")
    file_starts+=("$start")
    file_ends+=("$end")
  fi
done

# Create compressed version (remove whitespace, one line)
tr -d ' \t\n\r' < texteh/texteh_full_dump.txt > texteh/texteh_compressed_dump.txt

# Now, chunk the compressed.txt into smaller files
MAX_CHUNK_SIZE=5242880  # 5MB

# Use split to create chunks inside texteh
(
  cd texteh
  split -b $MAX_CHUNK_SIZE -d -a 3 texteh_compressed_dump.txt texteh_compressed_chunk_ --additional-suffix=.txt
)

# Get the list of chunk files, sorted
chunk_files=(texteh/texteh_compressed_chunk_*[0-9][0-9][0-9].txt)



# Create TOC
if [ -f texteh/texteh_chunk_toc.md ]; then
  rm texteh/texteh_chunk_toc.md
fi
touch texteh/texteh_chunk_toc.md
echo "| FILE | DESCRIPTION |" >> texteh/texteh_chunk_toc.md
echo "|------|-------------|" >> texteh/texteh_chunk_toc.md

current_start=0
for chunk_file in "${chunk_files[@]}"; do
  chunk_size=$(wc -c < "$chunk_file")
  chunk_end=$((current_start + chunk_size))

  # Find files that overlap with [current_start, chunk_end)
  covering_files=()
  for i in "${!file_list[@]}"; do
    f_start=${file_starts[$i]}
    f_end=${file_ends[$i]}
    if (( f_start < chunk_end && f_end > current_start )); then
      covering_files+=("${file_list[$i]}")
    fi
  done

  # Create brief description
  if [ ${#covering_files[@]} -eq 0 ]; then
    desc="Empty chunk or error."
  elif [ ${#covering_files[@]} -eq 1 ]; then
    desc="Covers part of file: ${covering_files[0]}."
  elif [ ${#covering_files[@]} -le 3 ]; then
    desc="Covers files: ${covering_files[*]}."
  else
    first=${covering_files[0]}
    last=${covering_files[-1]}
    desc="Covers files from $first to $last (and ${#covering_files[@]} total files)."
  fi

  # Ensure under 20 words (but it's brief)
  # Make chunk_file relative to project root for TOC
  rel_chunk_file=${chunk_file#"$PROJECT_ROOT/"}
  echo "| $rel_chunk_file | $desc |" >> texteh/texteh_chunk_toc.md

  current_start=$chunk_end
done

# Change back to original run directory
cd "$RUN_DIR"

echo "Done! textEh has created files in $PROJECT_ROOT/texteh/ : texteh_full_dump.txt, texteh_compressed_dump.txt, compressed chunk files, and texteh_chunk_toc.md (with backups if needed)."