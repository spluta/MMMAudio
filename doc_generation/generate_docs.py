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

from jinja2 import Environment, FileSystemLoader, TemplateNotFound

# ---------------- Hard‑coded whitelist of source directories ----------------
# These are relative to the repository root (one level above this script's dir).
REPO_ROOT = Path(__file__).resolve().parent.parent
HARDCODED_SOURCE_DIRS = [
    "mmm_utils",
    "mmm_dsp",
    "mmm_src",
    # Add/remove directory names here as needed
]

TEMPLATES_DIR = REPO_ROOT / 'doc_generation' / 'templates'

_env: Environment | None = None
def get_jinja_env() -> Environment:
    global _env
    if _env is None:
        _env = Environment(
            loader=FileSystemLoader(str(TEMPLATES_DIR)),
            autoescape=False,
            trim_blocks=True,
            lstrip_blocks=True,
        )
    return _env

def render_template(template_name: str, context: dict) -> str:
    env = get_jinja_env()
    try:
        tmpl = env.get_template(template_name)
    except TemplateNotFound:
        raise RuntimeError(f"Template '{template_name}' not found in {TEMPLATES_DIR}")
    return tmpl.render(**context)

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

def clean_mojo_doc_data(data: Dict[str, Any]) -> Dict[str, Any]:
    decl = data.get('decl', {})
    structs = decl.get('structs', [])
    for struct in structs:
        functions = struct.get('functions', [])
        # Drop unwanted functions first
        struct['functions'] = [
            f for f in functions
            if f.get('name') not in ('__init__', '__repr__')
        ]
        for func in struct['functions']:
            for ol in func.get('overloads', []):
                # Remove self from args
                args = ol.get('args', [])
                # before = len(args)
                ol['args'] = [a for a in args if a.get('name') != 'self']
                # if before != len(ol['args']):
                #     print(f"Removed 'self' arg from {func.get('name')} in struct {struct.get('name')}")
                # Also handle 'parameters' if present
                if 'parameters' in ol:
                    params = ol['parameters']
                    # p_before = len(params)
                    ol['parameters'] = [p for p in params if p.get('name') != 'self']
                    # if p_before != len(ol['parameters']):
                    #     print(f"Removed 'self' parameter from {func.get('name')} in struct {struct.get('name')}")
    return data

def process_mojo_sources(input_dir: Path, output_dir: Path, verbose: bool=False) -> bool:
    """Process all Mojo source files under input_dir and emit markdown into output_dir.

    Returns True if all files processed successfully.
    """
    if not input_dir.exists():
        print(f"Error: Input directory '{input_dir}' does not exist")
        return False
    if not input_dir.is_dir():
        print(f"Error: '{input_dir}' is not a directory")
        return False

    # Only collect mojo files from directories that contain source files, 
    # specified in the variable HARDCODED_SOURCE_DIRS. This avoids grabbing 
    # Mojo files from the examples directory (not source code) or other various places.
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
            data = clean_mojo_doc_data(data)
            rendered = render_template('mojo_doc_template_jinja.md', data)
            out_file.write_text(rendered, encoding='utf-8')
            processed += 1
        except Exception as e:
            errors += 1
            print(f"  Error: {e}")

    print("\nProcessing complete:")
    print(f"  Successfully processed: {processed} files")
    print(f"  Errors: {errors} files")
    return errors == 0

def process_example_file(example_file: Path):
    if not example_file.exists() or not example_file.is_file():
        print(f"Example file '{example_file}' does not exist or is not a file, skipping.")
        return

    example_name = example_file.stem  # filename without suffix
    output_md_path = REPO_ROOT / 'doc_generation' / 'docs_md' / 'examples' / f"{example_name}.md"
    output_md_path.parent.mkdir(parents=True, exist_ok=True)

    try:
        with open(example_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"Error reading example file '{example_file}': {e}")
        return
    
    # Find the code snippet, which is after the docstring, if there is a docstring
    code_start = 0
    code_end = len(lines)
    in_docstring = False
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith('"""') or stripped.startswith("'''"):
            if in_docstring:
                # End of docstring
                code_start = i + 1
                break
            else:
                # Start of docstring
                in_docstring = True
                if stripped.count('"""') == 2 or stripped.count("'''") == 2:
                    # Docstring starts and ends on the same line
                    in_docstring = False
                    code_start = i + 1
        elif in_docstring and (stripped.endswith('"""') or stripped.endswith("'''")):
            # End of multi-line docstring
            in_docstring = False
            code_start = i + 1
            break
        elif not in_docstring and stripped and not stripped.startswith('#'):
            # First non-comment, non-blank line outside docstring
            code_start = i
            break
        
    code = ''.join(lines[code_start:code_end]).rstrip()
    
    context = {
        'examplename': example_name,
        'code': code,
    }

    rendered = render_template('example_python_and_mojo_jinja.md', context)
    output_md_path.write_text(rendered, encoding='utf-8')
    print(f"Processed example '{example_file}' -> '{output_md_path}'")         

def process_examples_dir():
    example_files_src_dir = REPO_ROOT / 'examples'
    if not example_files_src_dir.exists() or not example_files_src_dir.is_dir():
        print(f"Examples directory '{example_files_src_dir}' does not exist or is not a directory, skipping examples processing.")
        return

    example_file_paths = list(example_files_src_dir.glob('*.py'))

    print(f"Found {len(example_file_paths)} example files to process.")
    
    for example_file in example_file_paths:
        print(f"Found example file: {example_file} {example_file.name}")
        if example_file.name == '__init__.py':
            print(f"Skipping file in examples directory: {example_file} {example_file.name}")
            continue
        process_example_file(example_file)

def copy_static_docs(output_dir: Path, args):
    static_docs_src = Path('doc_generation/static_docs')
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

def clean_output_dir(output_dir: Path, args):
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
        
def clean_docs_md(config=None):
    """MkDocs hook entry point - cleans up the generated docs_md directory contents."""
    output_dir = Path('./doc_generation/docs_md').resolve()
    if output_dir.exists() and output_dir.is_dir():
        print(f"[MkDocs Hook] Cleaning up contents of docs_md directory: {output_dir}")
        try:
            for child in output_dir.iterdir():
                if child.is_dir():
                    shutil.rmtree(child)
                else:
                    child.unlink()
            print(f"[MkDocs Hook] Successfully cleaned contents of {output_dir}")
        except Exception as e:
            print(f"[MkDocs Hook] Error cleaning contents of {output_dir}: {e}")
    else:
        print(f"[MkDocs Hook] No docs_md directory to clean at: {output_dir}")

def generate_docs_hook(config=None):
    """MkDocs hook entry point - generates docs with default settings."""
    
    # Repo root directory
    input_dir = Path('.').resolve()
    
    # Where all the generated markdown goes so that later mkdocs can pick it up
    output_dir = Path('./doc_generation/docs_md').resolve()
    
    print(f"[MkDocs Hook] Generating docs from {input_dir} to {output_dir}")
    
    # If it exists, clear ./doc_generation/docs_md so that there isn't any stale content lingering 
    if output_dir.exists():
        clean_output_dir(output_dir, type('args', (), {'verbose': True})())

    output_dir.mkdir(parents=True, exist_ok=True)

    # Copy ONLY the *contents* of static_docs into output_dir (not the directory itself)
    copy_static_docs(output_dir, type('args', (), {'verbose': True})())
        
    # use `mojo doc` to generate json files from Mojo source files
    # (however the json files are never actually saved to disk, the json string is 
    # passed to standard out and caught in Python to then be turned into a dict) 
    # and then use the json to render to markdown
    success = process_mojo_sources(
        input_dir=input_dir,
        output_dir=output_dir / 'api', # Place generated API docs under 'api' subdir
        verbose=True,
    )

    # Process all examples in the examples directory
    process_examples_dir()

    if not success:
        print("[MkDocs Hook] Documentation generation failed")
    else:
        print("[MkDocs Hook] Documentation generation completed successfully")

def main(config=None):
    """CLI entry point or MkDocs hook."""
    # If called as a hook (config passed), run the hook function
    if config is not None:
        return generate_docs_hook(config)
    
    # If not called as a hook, parse CLI arguments and run:
    
    parser = argparse.ArgumentParser(
        description="Recursively generate Markdown from Mojo source using `mojo doc` and a Jinja2 template.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s -i ./mmm_utils -o ./docs/api/mojo
  %(prog)s --input-dir ./ --output-dir ./docs/api/mojo --template doc_generation/templates/mojo_doc_template_jinja.md
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
        default='./doc_generation/docs_md',
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
    
    if args.verbose:
        print(f"Source root: {input_dir}")
        print(f"Output root: {output_dir}")

    if args.clean and output_dir.exists():
        clean_output_dir(output_dir, args)

    output_dir.mkdir(parents=True, exist_ok=True)

    # Copy ONLY the contents of static_docs_src into output_dir (not the directory itself)
    copy_static_docs(output_dir, args)
        
    success = process_mojo_sources(
        input_dir=input_dir,
        output_dir=output_dir / 'api', # Place generated API docs under 'api' subdir
        verbose=args.verbose,
    )

    process_examples_dir()

    if not success:
        sys.exit(1)

if __name__ == "__main__":
    main()