"""Generate Markdown documentation from Mojo source files.

This script recursively scans a directory for `.mojo` files, executes
`mojo doc <file.mojo>` to obtain structured JSON documentation, renders that
JSON through a Jinja2 Markdown template, and writes the resulting `.md` files
to an output directory while mirroring the original source tree structure.

Compared to the earlier JSON batch mode, this version avoids intermediate
JSON artifacts on disk and always reflects the current state of the source.

Exit status: 0 on full success, 1 if any file fails to document.
"""

from jinja2 import Template
import json
import argparse
import sys
import shutil
import subprocess
from pathlib import Path
from typing import Dict, Any, List

# ---------------- Hard‑coded whitelist of source directories ----------------
# These are relative to the repository root (one level above this script's dir).
REPO_ROOT = Path(__file__).resolve().parent.parent
HARDCODED_SOURCE_DIRS = [
    "mmm_utils",
    "mmm_dsp",
    "mmm_src",
    # Add/remove directory names here as needed
]

def render_template_str(template_str: str, context: Dict[str, Any]) -> str:
    """Render a Jinja2 template string with the given context."""
    template = Template(template_str)
    return template.render(**context)

def find_mojo_files(root: Path) -> List[Path]:
    """Return a list of all .mojo files under root (recursively)."""
    return [p for p in root.rglob("*.mojo") if p.is_file()]

def collect_whitelisted_mojo_files() -> List[Path]:
    """Gather .mojo files only from the hard-coded whitelisted directories."""
    files: List[Path] = []
    seen = set()
    for rel_dir in HARDCODED_SOURCE_DIRS:
        dir_path = REPO_ROOT / rel_dir
        if not dir_path.exists() or not dir_path.is_dir():
            continue
        for f in find_mojo_files(dir_path):
            if f not in seen:
                files.append(f)
                seen.add(f)
    return files

def run_mojo_doc(file_path: Path, timeout: int = 30) -> Dict[str, Any]:
    """Execute `mojo doc <file>` and return parsed JSON.

    Raises RuntimeError on non-zero exit or JSON parse error.
    """
    cmd = ["mojo", "doc", str(file_path)]
    try:
        completed = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
    except FileNotFoundError:
        raise RuntimeError("Mojo binary not found.")
    except subprocess.TimeoutExpired:
        raise RuntimeError(f"Timeout executing: {' '.join(cmd)}")

    if completed.returncode != 0:
        raise RuntimeError(
            f"mojo doc failed for {file_path} (exit {completed.returncode}):\nSTDERR:\n{completed.stderr.strip()}\nSTDOUT:\n{completed.stdout.strip()}"
        )

    stdout = completed.stdout.strip()
    if not stdout:
        raise RuntimeError(f"Empty output from mojo doc for {file_path}")
    try:
        return json.loads(stdout)
    except json.JSONDecodeError as e:
        # Keep a short prefix of the stdout for diagnostics
        snippet = stdout[:400]
        raise RuntimeError(f"Invalid JSON from mojo doc for {file_path}: {e}\nOutput snippet:\n{snippet}")


def process_mojo_sources(input_dir: Path, output_dir: Path, template_path: Path, verbose: bool=False) -> bool:
    """Process all Mojo source files under input_dir and emit markdown into output_dir.

    Returns True if all files processed successfully.
    """
    if not input_dir.exists():
        print(f"Error: Input directory '{input_dir}' does not exist")
        return False
    if not input_dir.is_dir():
        print(f"Error: '{input_dir}' is not a directory")
        return False
    if not template_path.exists():
        print(f"Error: Template file '{template_path}' does not exist")
        return False

    try:
        template_content = template_path.read_text(encoding='utf-8')
    except Exception as e:
        print(f"Error reading template file '{template_path}': {e}")
        return False

    mojo_files = collect_whitelisted_mojo_files()
    if not mojo_files:
        print(f"Warning: No .mojo files found in '{input_dir}'")
        return True

    print(f"Found {len(mojo_files)} .mojo files to process")
    processed = 0
    errors = 0

    for src_file in mojo_files:
        rel_path = src_file.relative_to(input_dir)
        # Mirror directory and replace suffix
        out_file = output_dir / rel_path.with_suffix('.md')
        out_file.parent.mkdir(parents=True, exist_ok=True)
        if verbose:
            print(f"→ {src_file} -> {out_file}")
        try:
            data = run_mojo_doc(src_file)
            rendered = render_template_str(template_content, data)
            out_file.write_text(rendered, encoding='utf-8')
            processed += 1
        except Exception as e:
            errors += 1
            print(f"  Error: {e}")

    print("\nProcessing complete:")
    print(f"  Successfully processed: {processed} files")
    print(f"  Errors: {errors} files")
    return errors == 0

def main():
    """CLI entry point."""
    parser = argparse.ArgumentParser(
        description="Recursively generate Markdown from Mojo source using `mojo doc` and a Jinja2 template.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s -i ./mmm_utils -o ./docs/api/mojo
  %(prog)s --input-dir ./ --output-dir ./docs/api/mojo --template doc-generation/templates/mojo_doc_template_jinja.md
  %(prog)s -i mmm_src -o docs/api/mojo -b /opt/mojo/bin/mojo -v
        """
    )

    parser.add_argument(
        '-i', '--input-dir',
        type=str,
        default='.',
        required=False,
        help='Root directory containing Mojo source files (recursively scanned)'
    )
    parser.add_argument(
        '-o', '--output-dir',
        type=str,
        default='./docs',
        required=False,
        help='Root directory where rendered Markdown will be written (mirrors source tree)'
    )
    parser.add_argument(
        '--clean', type=bool, default=True,
        help='Delete the entire output directory before generation (default: True)'
    )
    parser.add_argument(
        '-v', '--verbose', action='store_true', help='Enable verbose output'
    )

    args = parser.parse_args()

    input_dir = Path(args.input_dir).resolve()
    output_dir = Path(args.output_dir).resolve()
    template_path = Path('doc-generation/templates/mojo_doc_template_jinja.md').resolve()

    if args.verbose:
        print(f"Source root: {input_dir}")
        print(f"Output root: {output_dir}")
        print(f"Template: {template_path}")

    if args.clean and output_dir.exists():
        if args.verbose:
            print(f"Cleaning contents of output directory (preserving root): {output_dir}")
        try:
            for child in output_dir.iterdir():
                if child.is_dir():
                    shutil.rmtree(child)
                else:
                    try:
                        child.unlink()
                    except FileNotFoundError:
                        continue
            # ensure directory still exists
            output_dir.mkdir(parents=True, exist_ok=True)
        except Exception as e:  
            print(f"Error cleaning contents of output directory: {e}")
            sys.exit(1)

    output_dir.mkdir(parents=True, exist_ok=True)

    # Copy ONLY the contents of static_docs_src into output_dir (not the directory itself)
    static_docs_src = Path('doc-generation/static-docs')
    if static_docs_src.exists() and static_docs_src.is_dir():
        try:
            for item in static_docs_src.iterdir():
                dest = output_dir / item.name
                if item.is_dir():
                    shutil.copytree(item, dest, dirs_exist_ok=True)
                else:
                    shutil.copy2(item, dest)
                if args.verbose:
                    print(f"Copied {'dir' if item.is_dir() else 'file'}: {item} -> {dest}")
        except Exception as e:
            print(f"Error copying static docs contents: {e}")
            sys.exit(1)
    else:
        if args.verbose:
            print(f"No static docs directory at {static_docs_src}, skipping static content copy.")

    success = process_mojo_sources(
        input_dir=input_dir,
        output_dir=output_dir / 'api', # Place generated API docs under 'api' subdir
        template_path=template_path,
        verbose=args.verbose,
    )

    if not success:
        sys.exit(1)

if __name__ == "__main__":
    main()