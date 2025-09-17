#!/usr/bin/env python3
"""
Documentation Generation Pipeline for MMMAudio

This script orchestrates the complete documentation generation process for the
MMMAudio project, processing both Python and Mojo source files to create
comprehensive markdown documentation for MkDocs.

The pipeline includes:
1. Processing Mojo files with custom docstring extraction
2. Processing Python files with mkdocstrings  
3. Generating API reference structure
4. Creating example documentation
5. Building final documentation with MkDocs
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path
from typing import List, Dict
import argparse

# Add the documentation directory to Python path
sys.path.insert(0, str(Path(__file__).parent))

class DocumentationPipeline:
    """Main documentation generation pipeline for MMMAudio."""
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.docs_dir = project_root / "docs"
        self.api_dir = self.docs_dir / "api"
        self.examples_dir = self.docs_dir / "examples"
        
        # Source directories to process
        self.source_dirs = [
            "mmm_dsp",
            "mmm_src", 
            "mmm_utils"
        ]
        
        # Examples directory
        self.examples_source = project_root / "examples"
    
    def setup_docs_structure(self):
        """Create the documentation directory structure."""
        print("Setting up documentation structure...")
        
        # Create main docs directories
        self.docs_dir.mkdir(exist_ok=True)
        self.api_dir.mkdir(exist_ok=True)
        self.examples_dir.mkdir(exist_ok=True)
        
        # Create API subdirectories
        for source_dir in self.source_dirs:
            (self.api_dir / source_dir).mkdir(exist_ok=True)
        
        # Create development directory
        dev_dir = self.docs_dir / "development"
        dev_dir.mkdir(exist_ok=True)
    
    def process_python_files(self):
        """Generate markdown stubs for Python files to be processed by mkdocstrings."""
        print("Processing Python files...")
        
        python_files = []
        for source_dir in self.source_dirs:
            source_path = self.project_root / source_dir
            if source_path.exists():
                python_files.extend(source_path.glob("*.py"))
        
        for py_file in python_files:
            print(f"  Processing {py_file.relative_to(self.project_root)}")
            
            # Create markdown stub that mkdocstrings will process
            relative_path = py_file.relative_to(self.project_root)
            module_path = str(relative_path.with_suffix("")).replace("/", ".")
            
            output_dir = self.api_dir / relative_path.parent
            output_file = output_dir / f"{py_file.stem}.md"
            
            markdown_content = f"""# {relative_path}

::: {module_path}
"""
            
            with open(output_file, "w") as f:
                f.write(markdown_content)
            
            print(f"    Generated: {output_file.relative_to(self.docs_dir)}")
    
    def process_examples(self):
        """Process example files and create documentation."""
        print("Processing examples...")
        
        if not self.examples_source.exists():
            print("  No examples directory found")
            return
                
        # Process example files
        example_files = list(self.examples_source.glob("*.py")) + list(self.examples_source.glob("*.mojo"))
        
        for example_file in example_files:
                
            print(f"  Processing {example_file.name}")
            
            # Read the file and extract any docstrings
            try:
                content = example_file.read_text()
                
                # Extract module docstring if present
                docstring = ""
                if content.strip().startswith('"""'):
                    end_pos = content.find('"""', 3)
                    if end_pos != -1:
                        docstring = content[3:end_pos].strip()
                
                # Create example documentation
                # TODO: use jinja2 here rather than f-string
                markdown_content = f"""# {example_file.stem}

{docstring if docstring else f"Example demonstrating {example_file.stem} usage."}

## Source Code

```{'mojo' if example_file.suffix == '.mojo' else 'python'}
{content}
```

## Running This Example

```bash
{'mojo' if example_file.suffix == '.mojo' else 'python'} {example_file.relative_to(self.project_root)}
```
"""
                
                output_file = self.examples_dir / f"{example_file.stem}.md"
                with open(output_file, "w") as f:
                    f.write(markdown_content)
                
            except Exception as e:
                print(f"    Error processing {example_file.name}: {e}")
    
    def create_development_docs(self):
        """Create development and contribution documentation."""
        print("Creating development documentation...")
        
        dev_dir = self.docs_dir / "development"
        
        # TODO: copy the .md files into this directory
    
    def build_docs(self, serve: bool = False):
        """Build the documentation using mkdocs."""
        print("Building documentation with mkdocs...")
        
        try:
            if serve:
                # Serve the documentation locally
                subprocess.run(["mkdocs", "serve"], cwd=self.project_root, check=True)
            else:
                # Build the documentation
                subprocess.run(["mkdocs", "build"], cwd=self.project_root, check=True)
                print("Documentation built successfully in site/ directory")
        except subprocess.CalledProcessError as e:
            print(f"Error building documentation: {e}")
            return False
        except FileNotFoundError:
            print("Error: mkdocs not found. Install with: pip install -r requirements-docs.txt")
            return False
        
        return True
    
    def run_pipeline(self, serve: bool = False):
        """Run the complete documentation generation pipeline."""
        print("Starting MMMAudio documentation generation pipeline...")
        print(f"Project root: {self.project_root}")
        print(f"Docs directory: {self.docs_dir}")
        
        # Setup
        self.setup_docs_structure()
        
        # Generate content
        
        # TODO: copy the .md files
        # self.create_index_pages()
        
        # TODO: replace this with mojo doc which is a mojo package that extracts docstrings to json
        # self.process_mojo_files()
        
        self.process_python_files()
        self.process_examples()
        self.create_development_docs()
        
        # Build final docs
        if self.build_docs(serve=serve):
            print("\n✅ Documentation generation completed successfully!")
            if not serve:
                print("📁 Generated files:")
                print(f"   - HTML: {self.project_root}/site/")
                print(f"   - Source: {self.docs_dir}/")
                print("🌐 To serve locally: mkdocs serve")
                print("📄 To build PDF: mkdocs build (PDF included)")
        else:
            print("\n❌ Documentation generation failed!")
            return False
        
        return True


def main():
    """Main entry point for the documentation generation script."""
    parser = argparse.ArgumentParser(description="Generate MMMAudio documentation")
    parser.add_argument("--serve", action="store_true", 
                       help="Serve documentation locally instead of building")
    parser.add_argument("--project-root", type=Path, default=Path(__file__).parent.parent,
                       help="Path to project root directory")
    
    args = parser.parse_args()
    
    # Validate project root
    if not args.project_root.exists():
        print(f"Error: Project root {args.project_root} does not exist")
        return 1
    
    if not (args.project_root / "mkdocs.yml").exists():
        print(f"Error: mkdocs.yml not found in {args.project_root}")
        return 1
    
    # Run pipeline
    pipeline = DocumentationPipeline(args.project_root)
    success = pipeline.run_pipeline(serve=args.serve)
    
    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())