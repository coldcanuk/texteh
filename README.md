# textEh: A Codebase Dumper for Large Language Models

`textEh` is a simple yet powerful shell script that exports your entire git repository's codebase into a set of text files. It's designed specifically to help you provide a comprehensive, holistic context of your project to Large Language Models (LLMs), enabling more accurate and insightful analysis, refactoring, and documentation generation.

## Why Use `textEh` with LLMs?

When interacting with LLMs through IDE plugins, APIs, or standard chatbots, the model's understanding is often limited to small, isolated snippets of your code. This lack of full context can lead to suggestions that are incomplete, incorrect, or fail to grasp the overall architecture of your project.

`textEh` solves this problem by providing the LLM with a complete, self-contained snapshot of your entire codebase.

### Key Advantages Over Traditional Methods

1.  **Holistic Project Context:**
    *   **The Problem:** An API call might fetch a single function or class, but the LLM won't know how that code is used elsewhere in the project. It misses dependencies, inheritance patterns, and the overall design philosophy.
    *   **The `textEh` Solution:** By concatenating all relevant files (while respecting your `.gitignore`), `textEh` gives the LLM a bird's-eye view of your repository. The model can see the relationship between a utility function and the various parts of the application that call it, leading to much smarter and context-aware responses.

2.  **Superior to a Standard Chatbot:**
    *   **The Problem:** A generic chatbot has zero knowledge of your local, private codebase. You can paste snippets, but this is slow, inefficient, and you quickly hit token limits.
    *   **The `textEh` Solution:** You can upload the compressed output from `textEh` as a document to an advanced LLM. This effectively "trains" the model on your specific project, turning a general-purpose AI into a dedicated expert on your code.

3.  **Efficiency and Compatibility:**
    *   **Compressed Output:** The `texteh_compressed_dump.txt` file removes all whitespace, dramatically shrinking the file size and allowing you to fit a much larger amount of code into an LLM's context window.
    *   **Intelligent Chunking:** For models with stricter context limits, `textEh` automatically splits the compressed code into manageable chunks (e.g., 5MB).
    *   **Table of Contents (TOC):** Crucially, it also generates `texteh_chunk_toc.md`, which acts as a map. This TOC file tells the LLM which source files are contained within each chunk, allowing it to navigate the project structure logically.

## How It Works

When you run `texteh.sh` in your repository, it creates a `texteh/` directory with the following files:

*   **`texteh_full_dump.txt`**: A human-readable dump of all your project files, with clear separators (`=== path/to/file.js ===`) between each one.
*   **`texteh_compressed_dump.txt`**: A single-line, whitespace-removed version of the full dump, optimized for maximizing the data fed to an LLM.
*   **`texteh_compressed_chunk_*.txt`**: The compressed dump split into smaller, numbered files for easy uploading.
*   **`texteh_chunk_toc.md`**: A Markdown table that maps the chunk files to the original source files they contain, giving the LLM a guide to your codebase.

The script respects your `.gitignore` file, so temporary files, build artifacts, and sensitive information are automatically excluded.

## Usage

1.  Place the `texteh.sh` script in your project's root directory (or anywhere in your `$PATH`).
2.  Make sure it's executable: `chmod +x texteh.sh`.
3.  Run the script from anywhere inside your git repository:
    ```bash
    ./texteh.sh
    ```
4.  The output files will be generated in a new `texteh` folder at the root of your repository.

## Requirements

*   `bash`
*   `git` (must be run inside a git repository)
*   Standard Unix utilities (`cat`, `tr`, `wc`, `split`, etc.)

---

*This program is distributed under the terms of the GNU General Public License v3.*